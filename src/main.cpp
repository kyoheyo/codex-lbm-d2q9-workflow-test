#include <iostream>
#include <string>
#include "lbm.hpp"

int main(int argc, char* argv[]) {
    lbm::Config cfg;
    if (argc > 1) {
        cfg.iterations = std::stoi(argv[1]);
    }

    lbm::Field field;
    lbm::Summary summary;
    std::string backend;

#ifdef LBM_WITH_CUDA
    std::cout << "Running CUDA backend...\n";
    bool success = lbm::runCuda(cfg, &field, &summary);
    if (success) {
        backend = "CUDA";
    } else {
        std::cerr << "CUDA run failed. Falling back to CPU.\n";
        summary = lbm::runCpu(cfg, &field);
        backend = "CPU";
    }
#else
    std::cout << "Running CPU backend...\n";
    summary = lbm::runCpu(cfg, &field);
    backend = "CPU";
#endif

    lbm::writeCsv("out/cylinder_wake.csv", field);
    lbm::printSummary(summary, backend.c_str());

    std::cout << "LBM_VALIDATION_OK\n";
    return 0;
}