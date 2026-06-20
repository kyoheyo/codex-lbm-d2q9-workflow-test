#pragma once

#include <array>
#include <string>
#include <vector>

namespace lbm {

constexpr int Q = 9;
extern const int Cx[Q];
extern const int Cy[Q];
extern const int Opposite[Q];
extern const double W[Q];

struct Config {
    int nx = 160;
    int ny = 80;
    int iterations = 180;
    double tau = 0.56;
    double inletUx = 0.06;
    double inletUy = 0.0;
    double cylinderX = 40.0;
    double cylinderY = 40.0;
    double cylinderRadius = 10.0;
};

struct Field {
    int nx = 0;
    int ny = 0;
    std::vector<double> rho;
    std::vector<double> ux;
    std::vector<double> uy;
    std::vector<unsigned char> solid;
};

struct Summary {
    int nx = 0;
    int ny = 0;
    int iterations = 0;
    double rhoMin = 0.0;
    double rhoMax = 0.0;
    double sampleUx = 0.0;
    double sampleUy = 0.0;
    double mass = 0.0;
};

std::array<double, Q> equilibrium(double rho, double ux, double uy);
std::vector<unsigned char> makeCylinderMask(int nx, int ny, double cx, double cy, double radius);
Summary runCpu(const Config& cfg, Field* outField = nullptr);
bool runCuda(const Config& cfg, Field* outField, Summary* outSummary);
void writeCsv(const std::string& path, const Field& field, int stride = 2);
void printSummary(const Summary& summary, const char* backend);

}  // namespace lbm

