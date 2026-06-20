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
    // Validate config
    if (cfg.nx <= 0 || cfg.ny <= 0 || cfg.iterations <= 0 || cfg.tau <= 0.0) {
        throw std::invalid_argument("Invalid configuration: nx, ny, iterations, and tau must be positive");
    }
    if (cfg.tau <= 0.5) {
        throw std::invalid_argument("Invalid configuration: tau must be greater than 0.5");
    }
    
    const int nx = cfg.nx;
    const int ny = cfg.ny;
    const int size = nx * ny;

    // Initialize fields
    std::vector<double> f(size * Q, 0.0);
    std::vector<double> f_next(size * Q, 0.0);
    std::vector<double> rho(size, 1.0);
    std::vector<double> ux(size, 0.0);
    std::vector<double> uy(size, 0.0);
    std::vector<unsigned char> solid = makeCylinderMask(nx, ny, cfg.cylinderX, cfg.cylinderY, cfg.cylinderRadius);

    // Initial velocity profile: parabolic inflow at left boundary
    for (int y = 0; y < ny; ++y) {
        const double dy = static_cast<double>(y) - static_cast<double>(ny) / 2.0;
        const double uy_in = cfg.inletUx * (1.0 - (dy * dy) / (static_cast<double>(ny) * static_cast<double>(ny) / 4.0));
        const int idx = y * nx;
        ux[idx] = cfg.inletUx;
        uy[idx] = uy_in;
    }

    // Compute initial f from equilibrium
    for (int i = 0; i < size; ++i) {
        auto feq = equilibrium(rho[i], ux[i], uy[i]);
        for (int q = 0; q < Q; ++q) {
            f[i * Q + q] = feq[q];
        }
    }

    // Main simulation loop
    Summary summary;
    summary.nx = nx;
    summary.ny = ny;
    summary.iterations = cfg.iterations;

    for (int iter = 0; iter < cfg.iterations; ++iter) {
        // Collision step
        for (int i = 0; i < size; ++i) {
            if (solid[i]) continue;

            // Compute macroscopic quantities
            rho[i] = 0.0;
            ux[i] = 0.0;
            uy[i] = 0.0;
            for (int q = 0; q < Q; ++q) {
                rho[i] += f[i * Q + q];
                ux[i] += f[i * Q + q] * Cx[q];
                uy[i] += f[i * Q + q] * Cy[q];
            }
            ux[i] /= rho[i];
            uy[i] /= rho[i];

            // Collision: BGK
            auto feq = equilibrium(rho[i], ux[i], uy[i]);
            for (int q = 0; q < Q; ++q) {
                f[i * Q + q] = f[i * Q + q] + (1.0 / cfg.tau) * (feq[q] - f[i * Q + q]);
            }
        }

        // Clear next buffer every step
        std::fill(f_next.begin(), f_next.end(), 0.0);

        // Streaming step with non-periodic boundaries
        for (int i = 0; i < size; ++i) {
            if (solid[i]) {
                // Cylinder bounce-back: swap populations with opposite directions
                for (int q = 0; q < Q; ++q) {
                    const int opp = Opposite[q];
                    f_next[i * Q + q] = f[i * Q + opp];
                }
                continue;
            }

            const int x = i % nx;
            const int y = i / nx;

            // Handle boundaries
            for (int q = 0; q < Q; ++q) {
                const int x_new = x + Cx[q];
                const int y_new = y + Cy[q];
                const int i_new = y_new * nx + x_new;
                
                // Left boundary (inlet) - velocity inlet
                if (x_new < 0 && y_new >= 0 && y_new < ny) {
                    // Use equilibrium with inlet velocity
                    auto feq_inlet = equilibrium(rho[i], cfg.inletUx, 0.0);
                    f_next[i * Q + q] = feq_inlet[q];
                    continue;
                }
                
                // Right boundary (outlet) - zero-gradient
                if (x_new >= nx && y_new >= 0 && y_new < ny) {
                    // Copy from adjacent cell (zero-gradient)
                    const int i_adj = y_new * nx + (nx - 1);
                    f_next[i_adj * Q + q] = f[i * Q + q];
                    continue;
                }
                
                // Top boundary (bounce-back)
                if (y_new < 0 && x_new >= 0 && x_new < nx) {
                    // Bounce-back: swap with opposite direction
                    const int opp = Opposite[q];
                    const int i_top = 0 * nx + x_new;
                    f_next[i_top * Q + q] = f[i_top * Q + opp];
                    continue;
                }
                
                // Bottom boundary (bounce-back)
                if (y_new >= ny && x_new >= 0 && x_new < nx) {
                    // Bounce-back: swap with opposite direction
                    const int opp = Opposite[q];
                    const int i_bottom = (ny - 1) * nx + x_new;
                    f_next[i_bottom * Q + q] = f[i_bottom * Q + opp];
                    continue;
                }
                
                // Regular interior streaming
                if (x_new >= 0 && x_new < nx && y_new >= 0 && y_new < ny) {
                    f_next[i_new * Q + q] = f[i * Q + q];
                }
            }
        }

        // Swap f and f_next
        f.swap(f_next);

        // Update summary statistics every 10 iterations
        if (iter % 10 == 0 || iter == cfg.iterations - 1) {
            double rhoMin = *std::min_element(rho.begin(), rho.end());
            double rhoMax = *std::max_element(rho.begin(), rho.end());
            double mass = std::accumulate(rho.begin(), rho.end(), 0.0);
            summary.rhoMin = rhoMin;
            summary.rhoMax = rhoMax;
            summary.mass = mass;
            summary.sampleUx = ux[size / 2];
            summary.sampleUy = uy[size / 2];
        }
    }

    // Recompute final rho/ux/uy before summary
    for (int i = 0; i < size; ++i) {
        if (solid[i]) continue;
        rho[i] = 0.0;
        ux[i] = 0.0;
        uy[i] = 0.0;
        for (int q = 0; q < Q; ++q) {
            rho[i] += f[i * Q + q];
            ux[i] += f[i * Q + q] * Cx[q];
            uy[i] += f[i * Q + q] * Cy[q];
        }
        ux[i] /= rho[i];
        uy[i] /= rho[i];
    }

    // Update summary from final fields
    double rhoMin = *std::min_element(rho.begin(), rho.end());
    double rhoMax = *std::max_element(rho.begin(), rho.end());
    double mass = std::accumulate(rho.begin(), rho.end(), 0.0);
    summary.rhoMin = rhoMin;
    summary.rhoMax = rhoMax;
    summary.mass = mass;
    summary.sampleUx = ux[size / 2];
    summary.sampleUy = uy[size / 2];

    // Output field if requested
    if (outField != nullptr) {
        outField->nx = nx;
        outField->ny = ny;
        outField->rho = std::move(rho);
        outField->ux = std::move(ux);
        outField->uy = std::move(uy);
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
