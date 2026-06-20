#include "lbm.hpp"

#include <cmath>
#include <algorithm>
#include <numeric>
#include <vector>
#include <stdexcept>
#include <cstdio>

namespace lbm {

// D2Q9 lattice velocities
const int Cx[Q] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
const int Cy[Q] = {0, 0, 1, 0, -1, 1, 1, -1, -1};

// Opposite indices for each direction
const int Opposite[Q] = {0, 3, 4, 1, 2, 7, 8, 5, 6};

// Weights for D2Q9 lattice
const double W[Q] = {4.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
                      1.0 / 36.0, 1.0 / 36.0, 1.0 / 36.0, 1.0 / 36.0};

std::array<double, Q> equilibrium(double rho, double ux, double uy) {
    std::array<double, Q> feq;
    for (int q = 0; q < Q; ++q) {
        const double cu = Cx[q] * ux + Cy[q] * uy;
        feq[q] = W[q] * rho * (1.0 + 3.0 * cu + 4.5 * cu * cu - 1.5 * (ux * ux + uy * uy));
    }
    return feq;
}

std::vector<unsigned char> makeCylinderMask(int nx, int ny, double cx, double cy, double radius) {
    std::vector<unsigned char> mask(nx * ny, 0);
    const double r2 = radius * radius;
    for (int y = 0; y < ny; ++y) {
        for (int x = 0; x < nx; ++x) {
            const double dx = static_cast<double>(x) - cx;
            const double dy = static_cast<double>(y) - cy;
            if (dx * dx + dy * dy <= r2) {
                mask[y * nx + x] = 1;
            }
        }
    }
    return mask;
}

Summary runCpu(const Config& cfg, Field* outField) {
    // ---- Validate config --------------------------------------------------
    if (cfg.nx <= 0 || cfg.ny <= 0 || cfg.iterations <= 0 || cfg.tau <= 0.0) {
        throw std::invalid_argument("Invalid configuration: nx, ny, iterations, and tau must be positive");
    }
    if (cfg.tau <= 0.5) {
        throw std::invalid_argument("Invalid configuration: tau must be greater than 0.5");
    }

    const int nx = cfg.nx;
    const int ny = cfg.ny;
    const int size = nx * ny;
    const double omega = 1.0 / cfg.tau;

    // ---- Allocate fields --------------------------------------------------
    std::vector<double> f(size * Q, 0.0);
    std::vector<double> f_next(size * Q, 0.0);
    std::vector<double> rho(size, 1.0);
    std::vector<double> ux(size, 0.0);
    std::vector<double> uy(size, 0.0);
    std::vector<unsigned char> solid = makeCylinderMask(nx, ny, cfg.cylinderX, cfg.cylinderY, cfg.cylinderRadius);

    // ---- Initialize: uniform inlet velocity, equilibrium everywhere -------
    for (int i = 0; i < size; ++i) {
        const double ux0 = solid[i] ? 0.0 : cfg.inletUx;
        const double uy0 = 0.0;
        const double rho0 = 1.0;
        ux[i] = ux0;
        uy[i] = uy0;
        rho[i] = rho0;
        const double usq = ux0 * ux0 + uy0 * uy0;
        for (int q = 0; q < Q; ++q) {
            const double cu = Cx[q] * ux0 + Cy[q] * uy0;
            f[i * Q + q] = W[q] * rho0 * (1.0 + 3.0 * cu + 4.5 * cu * cu - 1.5 * usq);
        }
    }

    // ---- Summary ----------------------------------------------------------
    Summary summary;
    summary.nx = nx;
    summary.ny = ny;
    summary.iterations = cfg.iterations;

    // ---- Main time-stepping loop ------------------------------------------
    for (int iter = 0; iter < cfg.iterations; ++iter) {

        // ----- Collision (in-place on f, skip solid cells) -----------------
        for (int i = 0; i < size; ++i) {
            if (solid[i]) continue;

            // Compute macroscopic moments
            double r = 0.0, xu = 0.0, yu = 0.0;
            for (int q = 0; q < Q; ++q) {
                const double fi = f[i * Q + q];
                r  += fi;
                xu += fi * Cx[q];
                yu += fi * Cy[q];
            }
            // Guard against zero/negative density
            if (r < 1e-12) r = 1.0;
            xu /= r;
            yu /= r;

            rho[i] = r;
            ux[i]  = xu;
            uy[i]  = yu;

            // BGK relaxation
            const double usq = xu * xu + yu * yu;
            for (int q = 0; q < Q; ++q) {
                const double cu  = Cx[q] * xu + Cy[q] * yu;
                const double feq = W[q] * r * (1.0 + 3.0 * cu + 4.5 * cu * cu - 1.5 * usq);
                f[i * Q + q] += omega * (feq - f[i * Q + q]);
            }
        }

        // ----- Streaming (pull scheme: f -> f_next) ------------------------
        std::fill(f_next.begin(), f_next.end(), 0.0);

        for (int i = 0; i < size; ++i) {
            if (solid[i]) continue;   // skip solid destinations

            const int x = i % nx;
            const int y = i / nx;

            for (int d = 0; d < Q; ++d) {
                const int src_x = x - Cx[d];
                const int src_y = y - Cy[d];

                if (src_x >= 0 && src_x < nx && src_y >= 0 && src_y < ny) {
                    // Source is inside the domain
                    const int src = src_y * nx + src_x;
                    if (solid[src]) {
                        // Cylinder bounce-back: particle originates from solid
                        f_next[i * Q + d] = f[i * Q + Opposite[d]];
                    } else {
                        // Normal pull from fluid neighbour
                        f_next[i * Q + d] = f[src * Q + d];
                    }
                } else if (src_x < 0) {
                    // Left inlet: placeholder (fixed by inlet BC below)
                    f_next[i * Q + d] = f[i * Q + d];
                } else if (src_x >= nx) {
                    // Right outlet: placeholder (fixed by outlet BC below)
                    f_next[i * Q + d] = f[i * Q + d];
                } else {
                    // Top / bottom wall (src_y out of range): bounce-back
                    f_next[i * Q + d] = f[i * Q + Opposite[d]];
                }
            }
        }

        // ----- Inlet BC: Zou/He velocity inlet at x = 0 --------------------
        for (int y = 0; y < ny; ++y) {
            const int i = y * nx;   // x = 0
            if (solid[i]) continue;

            const double f0 = f_next[i * Q + 0];
            const double f2 = f_next[i * Q + 2];
            const double f4 = f_next[i * Q + 4];
            const double f3 = f_next[i * Q + 3];
            const double f6 = f_next[i * Q + 6];
            const double f7 = f_next[i * Q + 7];

            // Density from known populations + prescribed ux
            double rho_in = (f0 + f2 + f4 + 2.0 * (f3 + f6 + f7)) / (1.0 - cfg.inletUx);

            // Guard against unphysical density
            if (rho_in < 0.5 || rho_in > 3.0) {
                rho_in = 1.0;
            }

            // Zou/He: set unknown incoming populations
            f_next[i * Q + 1] = f3 + (2.0 / 3.0) * rho_in * cfg.inletUx;
            f_next[i * Q + 5] = f7 - 0.5 * (f2 - f4) + (1.0 / 6.0) * rho_in * cfg.inletUx;
            f_next[i * Q + 8] = f6 + 0.5 * (f2 - f4) + (1.0 / 6.0) * rho_in * cfg.inletUx;
        }

        // ----- Outlet BC: zero-gradient at x = nx-1 ------------------------
        for (int y = 0; y < ny; ++y) {
            const int i     = y * nx + (nx - 1);   // x = nx-1
            const int i_adj = y * nx + (nx - 2);   // x = nx-2
            if (solid[i]) continue;

            // Copy unknown (incoming from right) populations from second-to-last column
            f_next[i * Q + 3] = f_next[i_adj * Q + 3];
            f_next[i * Q + 6] = f_next[i_adj * Q + 6];
            f_next[i * Q + 7] = f_next[i_adj * Q + 7];
        }

        // ----- Swap double buffers -----------------------------------------
        f.swap(f_next);
    }

    // ---- Final macroscopic state ------------------------------------------
    for (int i = 0; i < size; ++i) {
        if (solid[i]) {
            rho[i] = 1.0;
            ux[i]  = 0.0;
            uy[i]  = 0.0;
            continue;
        }
        double r = 0.0, xu = 0.0, yu = 0.0;
        for (int q = 0; q < Q; ++q) {
            const double fi = f[i * Q + q];
            r  += fi;
            xu += fi * Cx[q];
            yu += fi * Cy[q];
        }
        if (r > 1e-12) { xu /= r; yu /= r; }
        else           { xu = 0.0; yu = 0.0; r = 1.0; }
        rho[i] = r;
        ux[i]  = xu;
        uy[i]  = yu;
    }

    // ---- Final summary ----------------------------------------------------
    {
        double rhoMin =  1e30;
        double rhoMax = -1e30;
        double mass   =  0.0;
        for (int i = 0; i < size; ++i) {
            if (solid[i]) continue;
            const double ri = rho[i];
            mass += ri;
            if (ri < rhoMin) rhoMin = ri;
            if (ri > rhoMax) rhoMax = ri;
        }
        summary.rhoMin = rhoMin;
        summary.rhoMax = rhoMax;
        summary.mass   = mass;

        int sx = static_cast<int>(cfg.cylinderX + 2.5 * cfg.cylinderRadius);
        int sy = static_cast<int>(cfg.cylinderY);
        if (sx >= nx) sx = nx - 1;
        if (sy <  0) sy = 0;
        if (sy >= ny) sy = ny - 1;
        const int si = sy * nx + sx;
        summary.sampleUx = ux[si];
        summary.sampleUy = uy[si];
    }

    // ---- Output field -----------------------------------------------------
    if (outField != nullptr) {
        outField->nx    = nx;
        outField->ny    = ny;
        outField->rho   = std::move(rho);
        outField->ux    = std::move(ux);
        outField->uy    = std::move(uy);
        outField->solid = std::move(solid);
    }

    return summary;
}

void writeCsv(const std::string& path, const Field& field, int stride) {
    FILE* f = fopen(path.c_str(), "w");
    if (!f) return;

    // Write header
    fprintf(f, "x,y,rho,ux,uy\n");

    // Write data points
    for (int y = 0; y < field.ny; y += stride) {
        for (int x = 0; x < field.nx; x += stride) {
            const int idx = y * field.nx + x;
            fprintf(f, "%d,%d,%f,%f,%f\n", x, y,
                    field.rho[idx], field.ux[idx], field.uy[idx]);
        }
    }

    fclose(f);
}

void printSummary(const Summary& summary, const char* backend) {
    printf("%s Summary:\n", backend);
    printf("  Grid size: %dx%d\n", summary.nx, summary.ny);
    printf("  Iterations: %d\n", summary.iterations);
    printf("  Density range: [%.6f, %.6f]\n", summary.rhoMin, summary.rhoMax);
    printf("  Mass: %.6f\n", summary.mass);
    printf("  Sample velocity (center): (%.6f, %.6f)\n",
           summary.sampleUx, summary.sampleUy);
}

}  // namespace lbm
