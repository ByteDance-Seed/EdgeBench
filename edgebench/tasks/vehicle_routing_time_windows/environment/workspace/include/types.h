// Common data types for CVRPTW solver. The ABI does not require Agent
// to use these structs — they are provided as a starting convenience.
#pragma once

#include <cstdint>
#include <cmath>
#include <string>
#include <vector>

namespace cvrptw {

struct Node {
    int id;            // 0 == depot
    double x, y;
    int demand;
    double e;          // earliest service start
    double l;          // latest service start
    double s;          // service duration
};

struct Instance {
    std::string name;
    int n_customers;   // not counting depot
    int capacity;
    int max_vehicles;
    std::vector<Node> nodes;   // size == n_customers + 1; nodes[0] is depot
};

struct Route {
    std::vector<int> seq;   // customer IDs only (depot 0 implicit at start/end)
    int load = 0;
    double cost = 0.0;
};

struct Solution {
    std::vector<Route> routes;
    double total_cost = 0.0;
    int num_vehicles() const { return static_cast<int>(routes.size()); }
};

// Standard CVRPTW distance: EUC_2D_X10 — round to 0.1 precision.
inline double dist_x10(const Node& a, const Node& b) {
    double dx = a.x - b.x;
    double dy = a.y - b.y;
    double d  = std::sqrt(dx * dx + dy * dy);
    return std::round(d * 10.0) / 10.0;
}

}  // namespace cvrptw
