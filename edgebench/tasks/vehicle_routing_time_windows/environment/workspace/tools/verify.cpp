// Independent verifier for CVRPTW solutions.
// Checks: format compliance, customer uniqueness, capacity, time windows,
// and re-computes total distance with the standard EUC_2D_X10 formula.
//
// Build:  make tools/verify
// Run :   ./tools/verify <input.txt> <output.txt>
//
// Exit codes:
//   0  feasible & cost matches
//   1  infeasible (any violation)
//   2  IO / parse error

#include "../include/types.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

using namespace cvrptw;

static Instance parse_input(const std::string& path);   // shared with solver

static int fail(const std::string& msg) {
    std::fprintf(stderr, "INFEASIBLE: %s\n", msg.c_str());
    std::cout << "feasible: false\n";
    return 1;
}

static int parse_error(const std::string& msg) {
    std::fprintf(stderr, "PARSE_ERROR: %s\n", msg.c_str());
    std::cout << "feasible: false\nreason: parse_error\n";
    return 2;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <input.txt> <output.txt>\n", argv[0]);
        return 2;
    }
    Instance inst;
    try {
        inst = parse_input(argv[1]);
    } catch (...) {
        return parse_error("cannot parse input");
    }

    std::ifstream out(argv[2]);
    if (!out) return parse_error("cannot open output file");

    std::string line;
    int declared_NV = -1;
    double declared_cost = -1.0;
    std::vector<std::vector<int>> routes;
    std::regex route_re("^Route (\\d+): 0((?: \\d+)+) 0$");
    std::regex header_re("^Routes: (\\d+)$");
    std::regex cost_re("^Cost: (\\d+\\.\\d{2})$");

    while (std::getline(out, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == ' ')) line.pop_back();
        if (line.empty()) continue;
        std::smatch m;
        if (declared_NV < 0) {
            if (!std::regex_match(line, m, header_re))
                return parse_error("first line must be 'Routes: <N>'");
            declared_NV = std::stoi(m[1]);
            continue;
        }
        if (std::regex_match(line, m, route_re)) {
            std::vector<int> seq;
            std::istringstream iss(m[2].str());
            int c;
            while (iss >> c) seq.push_back(c);
            routes.push_back(std::move(seq));
            continue;
        }
        if (std::regex_match(line, m, cost_re)) {
            declared_cost = std::stod(m[1]);
            continue;
        }
        return parse_error("unrecognized line: " + line);
    }
    if (declared_NV < 0) return parse_error("missing Routes header");
    if (declared_cost < 0) return parse_error("missing Cost line");
    if ((int)routes.size() != declared_NV)
        return parse_error("Routes header mismatch declared NV=" + std::to_string(declared_NV) +
                           " but got " + std::to_string(routes.size()) + " route lines");
    if (declared_NV > inst.max_vehicles)
        return fail("NV=" + std::to_string(declared_NV) +
                    " exceeds MAX_VEHICLES=" + std::to_string(inst.max_vehicles));

    // R2: customer uniqueness
    int N = inst.n_customers;
    std::vector<int> cnt(N + 1, 0);
    for (auto& seq : routes) {
        for (int c : seq) {
            if (c <= 0 || c > N) return fail("invalid customer id " + std::to_string(c));
            cnt[c]++;
        }
    }
    for (int c = 1; c <= N; ++c) {
        if (cnt[c] == 0) return fail("customer " + std::to_string(c) + " not visited");
        if (cnt[c] >  1) return fail("customer " + std::to_string(c) + " visited " + std::to_string(cnt[c]) + " times");
    }

    // R3 + R4 + R5: capacity, time windows, distance recompute
    double total_cost = 0.0;
    for (size_t r = 0; r < routes.size(); ++r) {
        auto& seq = routes[r];
        int load = 0;
        double t = 0.0;
        int prev = 0;
        double rcost = 0.0;
        for (int c : seq) {
            double d = dist_x10(inst.nodes[prev], inst.nodes[c]);
            rcost += d;
            t += d;
            if (t < inst.nodes[c].e) t = inst.nodes[c].e;
            if (t > inst.nodes[c].l + 1e-6)
                return fail("route " + std::to_string(r + 1) + ": late at customer " +
                            std::to_string(c) + " (arrive " + std::to_string(t) +
                            ", l=" + std::to_string(inst.nodes[c].l) + ")");
            t   += inst.nodes[c].s;
            load += inst.nodes[c].demand;
            prev = c;
        }
        double back = dist_x10(inst.nodes[prev], inst.nodes[0]);
        rcost += back;
        t     += back;
        if (t > inst.nodes[0].l + 1e-6)
            return fail("route " + std::to_string(r + 1) + ": late returning to depot");
        if (load > inst.capacity)
            return fail("route " + std::to_string(r + 1) + ": load " +
                        std::to_string(load) + " > capacity " +
                        std::to_string(inst.capacity));
        total_cost += rcost;
    }

    if (std::fabs(total_cost - declared_cost) > 0.05) {
        char buf[128];
        std::snprintf(buf, sizeof(buf),
                      "declared cost %.2f vs recomputed %.2f (diff %.3f)",
                      declared_cost, total_cost,
                      std::fabs(total_cost - declared_cost));
        return fail(buf);
    }
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.2f", total_cost);
    std::cout << "feasible: true\n"
              << "NV: " << routes.size() << "\n"
              << "TD: " << buf << "\n";
    return 0;
}

// --- shared parser (kept identical to solver.cpp to ease maintenance) ---

namespace cvrptw {
static bool starts_with(const std::string& s, const char* p) {
    return s.compare(0, std::strlen(p), p) == 0;
}
}

static Instance parse_input(const std::string& path) {
    using cvrptw::starts_with;
    std::ifstream in(path);
    if (!in) throw std::runtime_error("cannot open input");
    Instance inst;
    int dim = 0;
    std::string line;
    enum Section { NONE, COORD, DEMAND, TW, SVC, DEPOT } sec = NONE;
    std::vector<std::tuple<int, double, double>> coords;
    std::vector<std::pair<int, int>> demands;
    std::vector<std::tuple<int, double, double>> tws;
    std::vector<std::pair<int, double>> svcs;
    while (std::getline(in, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == ' ' || line.back() == '\t'))
            line.pop_back();
        if (line.empty() || starts_with(line, "EOF")) continue;
        if (starts_with(line, "NAME")) { auto p = line.find(':'); inst.name = line.substr(p + 1); continue; }
        if (starts_with(line, "DIMENSION"))    { dim = std::atoi(line.c_str() + line.find(':') + 1); continue; }
        if (starts_with(line, "CAPACITY"))     { inst.capacity = std::atoi(line.c_str() + line.find(':') + 1); continue; }
        if (starts_with(line, "MAX_VEHICLES")) { inst.max_vehicles = std::atoi(line.c_str() + line.find(':') + 1); continue; }
        if (starts_with(line, "EDGE_WEIGHT_TYPE")) continue;
        if (starts_with(line, "NODE_COORD_SECTION"))   { sec = COORD; continue; }
        if (starts_with(line, "DEMAND_SECTION"))       { sec = DEMAND; continue; }
        if (starts_with(line, "TIME_WINDOW_SECTION"))  { sec = TW; continue; }
        if (starts_with(line, "SERVICE_TIME_SECTION")) { sec = SVC; continue; }
        if (starts_with(line, "DEPOT_SECTION"))        { sec = DEPOT; continue; }
        std::istringstream iss(line);
        if (sec == COORD)  { int id; double x, y; if (iss >> id >> x >> y) coords.emplace_back(id, x, y); }
        else if (sec == DEMAND) { int id, q; if (iss >> id >> q) demands.emplace_back(id, q); }
        else if (sec == TW)     { int id; double e, l; if (iss >> id >> e >> l) tws.emplace_back(id, e, l); }
        else if (sec == SVC)    { int id; double s; if (iss >> id >> s) svcs.emplace_back(id, s); }
    }
    if (dim <= 0) throw std::runtime_error("missing DIMENSION");
    inst.nodes.assign(dim, Node{});
    inst.n_customers = dim - 1;
    for (auto& [id, x, y] : coords) if (id >= 0 && id < dim) { inst.nodes[id].id = id; inst.nodes[id].x = x; inst.nodes[id].y = y; }
    for (auto& [id, q]    : demands) if (id >= 0 && id < dim) inst.nodes[id].demand = q;
    for (auto& [id, e, l] : tws)     if (id >= 0 && id < dim) { inst.nodes[id].e = e; inst.nodes[id].l = l; }
    for (auto& [id, s]    : svcs)    if (id >= 0 && id < dim) inst.nodes[id].s = s;
    return inst;
}
