#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <cassert>
#include <cmath>
#include "lbm.hpp"

// Test equilibrium function: check mass and momentum conservation
template<typename T>
void testEquilibrium() {
    std::cout << "Testing equilibrium()... ";
    double rho = 1.2;
    double ux = 0.1;
    double uy = -0.05;
    auto feq = lbm::equilibrium(rho, ux, uy);

    // Sum of feq must equal rho (mass conservation)
    double sumF = 0.0;
    for (double f : feq) sumF += f;
    assert(std::abs(sumF - rho) < 1e-12);

    // Sum of feq * Cx must equal rho * ux (x-momentum)
    double sumFx = 0.0;
    for (int q = 0; q < lbm::Q; ++q) {
        sumFx += feq[q] * lbm::Cx[q];
    }
    assert(std::abs(sumFx - rho * ux) < 1e-12);

    // Sum of feq * Cy must equal rho * uy (y-momentum)
    double sumFy = 0.0;
    for (int q = 0; q < lbm::Q; ++q) {
        sumFy += feq[q] * lbm::Cy[q];
    }
    assert(std::abs(sumFy - rho * uy) < 1e-12);

    std::cout << "OK\n";
}

// Test makeCylinderMask: verify circle center and radius
template<typename T>
void testCylinderMask() {
    std::cout << "Testing makeCylinderMask()... ";
    int nx = 100, ny = 100;
    double cx = 50.0, cy = 50.0, r = 10.0;
    auto mask = lbm::makeCylinderMask(nx, ny, cx, cy, r);

    // Center pixel must be solid
    int centerIdx = static_cast<int>(cy) * nx + static_cast<int>(cx);
    assert(mask[centerIdx] == 1);

    // Pixel just outside radius must be fluid
    int outerIdx = (static_cast<int>(cy) + 11) * nx + static_cast<int>(cx);
    assert(mask[outerIdx] == 0);

    // Count solid cells and verify reasonable match to pi*r*r
    int solidCount = 0;
    for (int i = 0; i < nx * ny; ++i) {
        if (mask[i] == 1) solidCount++;
    }
    double expectedArea = std::acos(-1.0) * r * r;
    double tolerance = 0.15 * expectedArea;
    assert(std::abs(solidCount - expectedArea) <= tolerance);

    std::cout << "OK\n";
}

int main() {
    testEquilibrium<double>();
    testCylinderMask<double>();
    std::cout << "LBM_TESTS_OK\n";
    return 0;
}