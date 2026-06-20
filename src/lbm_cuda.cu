#include "lbm.hpp"

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <algorithm>

/* ==========================================================================
   Device-side D2Q9 constants  (mirror lbm.hpp definitions for GPU use)
   ========================================================================== */
namespace {

__constant__ int    d_Cx[9];
__constant__ int    d_Cy[9];
__constant__ int    d_Opposite[9];
__constant__ double d_W[9];

constexpr int Q = 9;

/* ==========================================================================
   Kernel 1 -- initialise PDFs to equilibrium
   ========================================================================== */
__global__ void init_kernel(double* f, int nx, int ny,
                            double ux0, double uy0,
                            const unsigned char* solid)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= nx || y >= ny) return;
    int idx = y * nx + x;

    double rho = 1.0;
    double ux  = solid[idx] ? 0.0 : ux0;
    double uy  = solid[idx] ? 0.0 : uy0;
    double u2  = ux * ux + uy * uy;

    for (int d = 0; d < Q; ++d) {
        double cu  = d_Cx[d] * ux + d_Cy[d] * uy;
        f[idx * Q + d] = d_W[d] * rho
                       * (1.0 + 3.0 * cu + 4.5 * cu * cu - 1.5 * u2);
    }
}

/* ==========================================================================
   Kernel 2 -- BGK collision (skip solid cells)
   ========================================================================== */
__global__ void collide_kernel(double* f, int nx, int ny, double tau,
                                const unsigned char* solid)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= nx || y >= ny) return;
    int idx = y * nx + x;
    if (solid[idx]) return;

    /* local moments */
    double rho = 0.0, ux = 0.0, uy = 0.0;
    for (int d = 0; d < Q; ++d) {
        double fi = f[idx * Q + d];
        rho += fi;
        ux  += d_Cx[d] * fi;
        uy  += d_Cy[d] * fi;
    }
    if (rho > 1e-12) { ux /= rho; uy /= rho; }

    /* BGK relaxation */
    double u2    = ux * ux + uy * uy;
    double omega = 1.0 / tau;
    for (int d = 0; d < Q; ++d) {
        double cu  = d_Cx[d] * ux + d_Cy[d] * uy;
        double feq = d_W[d] * rho
                   * (1.0 + 3.0 * cu + 4.5 * cu * cu - 1.5 * u2);
        f[idx * Q + d] -= omega * (f[idx * Q + d] - feq);
    }
}

/* ==========================================================================
   Kernel 3 -- pull-streaming with cylinder bounce-back and wall bounce-back
   ========================================================================== */
__global__ void stream_kernel(const double* __restrict__ f_in,
                               double* __restrict__ f_out,
                               int nx, int ny,
                               const unsigned char* __restrict__ solid)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= nx || y >= ny) return;
    int idx = y * nx + x;
    if (solid[idx]) return;   /* solid destination - no streaming needed */

    for (int d = 0; d < Q; ++d) {
        int src_x = x - d_Cx[d];
        int src_y = y - d_Cy[d];

        if (src_x >= 0 && src_x < nx && src_y >= 0 && src_y < ny) {
            /* source is inside the domain */
            int src_idx = src_y * nx + src_x;
            if (solid[src_idx]) {
                /* cylinder bounce-back */
                f_out[idx * Q + d] = f_in[idx * Q + d_Opposite[d]];
            } else {
                /* normal pull */
                f_out[idx * Q + d] = f_in[src_idx * Q + d];
            }
        } else if (src_x < 0) {
            /* left-inlet placeholder -> fixed by inlet_kernel */
            f_out[idx * Q + d] = f_in[idx * Q + d];
        } else if (src_x >= nx) {
            /* right-outlet placeholder -> fixed by outlet_kernel */
            f_out[idx * Q + d] = f_in[idx * Q + d];
        } else {
            /* top / bottom wall (src_y out-of-range) -> bounce-back */
            f_out[idx * Q + d] = f_in[idx * Q + d_Opposite[d]];
        }
    }
}

/* ==========================================================================
   Kernel 4 -- Zou / He velocity inlet at x = 0  (uy = 0)
   ========================================================================== */
__global__ void inlet_kernel(double* f, int nx, int ny,
                              double inlet_ux, double /*inlet_uy*/,
                              const unsigned char* solid)
{
    int y = blockIdx.x * blockDim.x + threadIdx.x;
    if (y >= ny) return;
    int idx = y * nx;          /* x = 0 */
    if (solid[idx]) return;

    double f0 = f[idx * Q + 0];
    double f2 = f[idx * Q + 2];
    double f4 = f[idx * Q + 4];
    double f3 = f[idx * Q + 3];
    double f6 = f[idx * Q + 6];
    double f7 = f[idx * Q + 7];

    /* density from known populations + specified ux */
    double rho = (f0 + f2 + f4 + 2.0 * (f3 + f6 + f7)) / (1.0 - inlet_ux);

    /* bounce-back of non-equilibrium part for the three unknown directions */
    f[idx * Q + 1] = f3 + (2.0 / 3.0) * rho * inlet_ux;
    f[idx * Q + 5] = f7 - 0.5 * (f2 - f4) + (1.0 / 6.0) * rho * inlet_ux;
    f[idx * Q + 8] = f6 + 0.5 * (f2 - f4) + (1.0 / 6.0) * rho * inlet_ux;
}

/* ==========================================================================
   Kernel 5 -- zero-gradient outlet at x = nx-1
   ========================================================================== */
__global__ void outlet_kernel(double* f, int nx, int ny,
                               const unsigned char* solid)
{
    int y = blockIdx.x * blockDim.x + threadIdx.x;
    if (y >= ny) return;
    int idx     = y * nx + (nx - 1);   /* x = nx-1 */
    int src_idx = y * nx + (nx - 2);   /* x = nx-2 */
    if (solid[idx]) return;

    /* copy unknown (incoming) populations from second-to-last column */
    f[idx * Q + 3] = f[src_idx * Q + 3];
    f[idx * Q + 6] = f[src_idx * Q + 6];
    f[idx * Q + 7] = f[src_idx * Q + 7];
}

/* ==========================================================================
   Kernel 6 -- compute macroscopic (rho, ux, uy) from PDFs
   ========================================================================== */
__global__ void macro_kernel(const double* f,
                              double* rho, double* ux, double* uy,
                              int nx, int ny,
                              const unsigned char* solid)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= nx || y >= ny) return;
    int idx = y * nx + x;

    if (solid[idx]) {
        rho[idx] = 1.0;
        ux [idx] = 0.0;
        uy [idx] = 0.0;
        return;
    }

    double r = 0.0, u = 0.0, v = 0.0;
    for (int d = 0; d < Q; ++d) {
        double fi = f[idx * Q + d];
        r += fi;
        u += d_Cx[d] * fi;
        v += d_Cy[d] * fi;
    }
    if (r > 1e-12) { u /= r; v /= r; }

    rho[idx] = r;
    ux [idx] = u;
    uy [idx] = v;
}

}  /* anonymous namespace */

/* ==========================================================================
   Public entry point -- lbm::runCuda
   ========================================================================== */
bool lbm::runCuda(const lbm::Config& cfg,
                  lbm::Field*   outField,
                  lbm::Summary* outSummary)
{
    /* ---- 1. CUDA availability check -------------------------------- */
    int deviceCount = 0;
    cudaError_t cudaErr = cudaGetDeviceCount(&deviceCount);
    if (cudaErr != cudaSuccess || deviceCount == 0) {
        /* no CUDA-capable device -> clean false return */
        return false;
    }

    const int nx         = cfg.nx;
    const int ny         = cfg.ny;
    const int N          = nx * ny;
    const int iterations = cfg.iterations;

    /* ---- 2. Input validation --------------------------------------- */
    if (nx <= 0 || ny <= 0 || iterations <= 0 || cfg.tau <= 0.5) {
        return false;
    }

    /* ---- 3. Upload D2Q9 constants to __constant__ memory ----------- */
    {
        int    h_Cx[Q]       = { 0,  1,  0, -1,  0,  1, -1, -1,  1 };
        int    h_Cy[Q]       = { 0,  0,  1,  0, -1,  1,  1, -1, -1 };
        int    h_Opposite[Q] = { 0,  3,  4,  1,  2,  7,  8,  5,  6 };
        double h_W[Q]        = { 4.0 / 9.0,  1.0 / 9.0,  1.0 / 9.0,
                                 1.0 / 9.0,  1.0 / 9.0,
                                 1.0 / 36.0, 1.0 / 36.0, 1.0 / 36.0, 1.0 / 36.0 };

        cudaErr = cudaMemcpyToSymbol(d_Cx,       h_Cx,       Q * sizeof(int));
        if (cudaErr != cudaSuccess) return false;
        cudaErr = cudaMemcpyToSymbol(d_Cy,       h_Cy,       Q * sizeof(int));
        if (cudaErr != cudaSuccess) return false;
        cudaErr = cudaMemcpyToSymbol(d_Opposite, h_Opposite, Q * sizeof(int));
        if (cudaErr != cudaSuccess) return false;
        cudaErr = cudaMemcpyToSymbol(d_W,        h_W,        Q * sizeof(double));
        if (cudaErr != cudaSuccess) return false;
    }

    /* ---- 4. Solid mask (host -> device) ----------------------------- */
    std::vector<unsigned char> h_solid =
        lbm::makeCylinderMask(nx, ny,
                              cfg.cylinderX, cfg.cylinderY,
                              cfg.cylinderRadius);

    /* ---- 5. Launch configurations ---------------------------------- */
    dim3 block(16, 16);
    dim3 grid((nx + block.x - 1) / block.x,
              (ny + block.y - 1) / block.y);

    const int bcThreads = 256;
    const int bcBlocks  = (ny + bcThreads - 1) / bcThreads;

    /* ---- 6. Device allocations ------------------------------------- */
    unsigned char* d_solid = nullptr;
    double *d_f0  = nullptr;   /* primary PDF buffer */
    double *d_f1  = nullptr;   /* secondary PDF buffer (double-buffering) */
    double *d_rho = nullptr;
    double *d_ux  = nullptr;
    double *d_uy  = nullptr;

    cudaErr = cudaMalloc(&d_solid, N * sizeof(unsigned char));
    if (cudaErr != cudaSuccess) goto cleanup;
    cudaErr = cudaMalloc(&d_f0, N * Q * sizeof(double));
    if (cudaErr != cudaSuccess) goto cleanup;
    cudaErr = cudaMalloc(&d_f1, N * Q * sizeof(double));
    if (cudaErr != cudaSuccess) goto cleanup;
    cudaErr = cudaMalloc(&d_rho, N * sizeof(double));
    if (cudaErr != cudaSuccess) goto cleanup;
    cudaErr = cudaMalloc(&d_ux,  N * sizeof(double));
    if (cudaErr != cudaSuccess) goto cleanup;
    cudaErr = cudaMalloc(&d_uy,  N * sizeof(double));
    if (cudaErr != cudaSuccess) goto cleanup;

    cudaErr = cudaMemcpy(d_solid, h_solid.data(),
                         N * sizeof(unsigned char), cudaMemcpyHostToDevice);
    if (cudaErr != cudaSuccess) goto cleanup;

    /* ---- 7. Initialise PDFs ---------------------------------------- */
    init_kernel<<<grid, block>>>(d_f0, nx, ny,
                                 cfg.inletUx, cfg.inletUy, d_solid);
    cudaErr = cudaGetLastError();
    if (cudaErr != cudaSuccess) goto cleanup;

    /* ---- 8. Main time-stepping loop -------------------------------- */
    for (int iter = 0; iter < iterations; ++iter) {

        /* 8a. BGK collision (in-place on d_f0) */
        collide_kernel<<<grid, block>>>(d_f0, nx, ny, cfg.tau, d_solid);
        cudaErr = cudaGetLastError();
        if (cudaErr != cudaSuccess) goto cleanup;

        /* 8b. Streaming + cylinder bounce-back + wall bounce-back
         *     (pull: d_f0 -> d_f1) */
        stream_kernel<<<grid, block>>>(d_f0, d_f1, nx, ny, d_solid);
        cudaErr = cudaGetLastError();
        if (cudaErr != cudaSuccess) goto cleanup;

        /* 8c. Zou / He velocity inlet at x = 0 */
        inlet_kernel<<<bcBlocks, bcThreads>>>(d_f1, nx, ny,
                                              cfg.inletUx, cfg.inletUy,
                                              d_solid);
        cudaErr = cudaGetLastError();
        if (cudaErr != cudaSuccess) goto cleanup;

        /* 8d. Zero-gradient outlet at x = nx-1 */
        outlet_kernel<<<bcBlocks, bcThreads>>>(d_f1, nx, ny, d_solid);
        cudaErr = cudaGetLastError();
        if (cudaErr != cudaSuccess) goto cleanup;

        /* 8e. Swap double buffers */
        std::swap(d_f0, d_f1);
    }

    /* final synchronisation to catch any runtime errors */
    cudaErr = cudaDeviceSynchronize();
    if (cudaErr != cudaSuccess) goto cleanup;

    /* ---- 9. Compute macroscopic fields ----------------------------- */
    macro_kernel<<<grid, block>>>(d_f0, d_rho, d_ux, d_uy,
                                  nx, ny, d_solid);
    cudaErr = cudaGetLastError();
    if (cudaErr != cudaSuccess) goto cleanup;

    cudaErr = cudaDeviceSynchronize();
    if (cudaErr != cudaSuccess) goto cleanup;

    /* ---- 10. Copy results host <- device --------------------------- */
    {
        std::vector<double> h_rho(N), h_ux(N), h_uy(N);

        cudaErr = cudaMemcpy(h_rho.data(), d_rho,
                             N * sizeof(double), cudaMemcpyDeviceToHost);
        if (cudaErr != cudaSuccess) goto cleanup;
        cudaErr = cudaMemcpy(h_ux.data(), d_ux,
                             N * sizeof(double), cudaMemcpyDeviceToHost);
        if (cudaErr != cudaSuccess) goto cleanup;
        cudaErr = cudaMemcpy(h_uy.data(), d_uy,
                             N * sizeof(double), cudaMemcpyDeviceToHost);
        if (cudaErr != cudaSuccess) goto cleanup;

        /* ---- 11. Summary (uses local copies before any move) ------- */
        if (outSummary) {
            outSummary->nx         = nx;
            outSummary->ny         = ny;
            outSummary->iterations = iterations;

            double mass = 0.0;
            double rMin =  1e30;
            double rMax = -1e30;
            for (int i = 0; i < N; ++i) {
                if (h_solid[i]) continue;          /* exclude solid cells */
                double ri = h_rho[i];
                mass += ri;
                if (ri < rMin) rMin = ri;
                if (ri > rMax) rMax = ri;
            }
            outSummary->rhoMin = rMin;
            outSummary->rhoMax = rMax;
            outSummary->mass   = mass;

            /* sample velocity at a point downstream of the cylinder */
            int sx = static_cast<int>(cfg.cylinderX
                                      + 2.5 * cfg.cylinderRadius);
            int sy = static_cast<int>(cfg.cylinderY);
            if (sx >= nx) sx = nx - 1;
            if (sy <  0) sy = 0;
            if (sy >= ny) sy = ny - 1;
            int si = sy * nx + sx;
            outSummary->sampleUx = h_ux[si];
            outSummary->sampleUy = h_uy[si];
        }

        /* ---- 12. Populate output Field (moves host vectors) -------- */
        if (outField) {
            outField->nx    = nx;
            outField->ny    = ny;
            outField->rho   = std::move(h_rho);
            outField->ux    = std::move(h_ux);
            outField->uy    = std::move(h_uy);
            outField->solid = std::move(h_solid);
        }
    }

    /* ---- 13. Cleanup ----------------------------------------------- */
cleanup:
    cudaFree(d_solid);
    cudaFree(d_f0);
    cudaFree(d_f1);
    cudaFree(d_rho);
    cudaFree(d_ux);
    cudaFree(d_uy);

    return (cudaErr == cudaSuccess);
}
