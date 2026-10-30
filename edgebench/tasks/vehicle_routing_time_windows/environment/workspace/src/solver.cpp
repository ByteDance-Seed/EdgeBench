// CVRPTW baseline solver: Nearest-Neighbor construction with Push-Forward
// time-window feasibility check. Approx. 240 lines, no third-party deps.
//
// Build:  make
// Run :   ./cvrptw_solver <input.txt> <output.txt> <time_budget_sec>
//
// This is a deliberately simple baseline. Agents are expected to replace
// or extend it with stronger metaheuristics (ALNS, SISR, Tabu, etc.).

#include "../include/types.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>

using namespace cvrptw;
using Clock = std::chrono::steady_clock;

// ---------- IO ----------

static bool starts_with(const std::string& s, const char* p) {
    return s.compare(0, std::strlen(p), p) == 0;
}

static Instance parse_input(const std::string& path) {
    std::ifstream in(path);
    if (!in) {
        std::fprintf(stderr, "ERROR: cannot open input file: %s\n", path.c_str());
        std::exit(2);
    }
    Instance inst;
    int dim = 0;
    std::string line;
    enum Section { NONE, COORD, DEMAND, TW, SVC, DEPOT } sec = NONE;
    std::vector<std::tuple<int, double, double>> coords;
    std::vector<std::pair<int, int>> demands;
    std::vector<std::tuple<int, double, double>> tws;
    std::vector<std::pair<int, double>> svcs;
    while (std::getline(in, line)) {
        // strip trailing \r
        while (!line.empty() && (line.back() == '\r' || line.back() == ' ' || line.back() == '\t'))
            line.pop_back();
        if (line.empty() || starts_with(line, "EOF")) continue;
        if (starts_with(line, "NAME")) {
            auto pos = line.find(':');
            if (pos != std::string::npos) {
                inst.name = line.substr(pos + 1);
                while (!inst.name.empty() && inst.name.front() == ' ') inst.name.erase(inst.name.begin());
            }
            continue;
        }
        if (starts_with(line, "DIMENSION")) {
            auto pos = line.find(':');
            dim = std::atoi(line.c_str() + pos + 1);
            continue;
        }
        if (starts_with(line, "CAPACITY")) {
            auto pos = line.find(':');
            inst.capacity = std::atoi(line.c_str() + pos + 1);
            continue;
        }
        if (starts_with(line, "MAX_VEHICLES")) {
            auto pos = line.find(':');
            inst.max_vehicles = std::atoi(line.c_str() + pos + 1);
            continue;
        }
        if (starts_with(line, "EDGE_WEIGHT_TYPE")) continue;
        if (starts_with(line, "NODE_COORD_SECTION"))  { sec = COORD;  continue; }
        if (starts_with(line, "DEMAND_SECTION"))      { sec = DEMAND; continue; }
        if (starts_with(line, "TIME_WINDOW_SECTION")) { sec = TW;     continue; }
        if (starts_with(line, "SERVICE_TIME_SECTION")){ sec = SVC;    continue; }
        if (starts_with(line, "DEPOT_SECTION"))       { sec = DEPOT;  continue; }
        std::istringstream iss(line);
        if (sec == COORD) {
            int id; double x, y;
            if (iss >> id >> x >> y) coords.emplace_back(id, x, y);
        } else if (sec == DEMAND) {
            int id, q;
            if (iss >> id >> q) demands.emplace_back(id, q);
        } else if (sec == TW) {
            int id; double e, l;
            if (iss >> id >> e >> l) tws.emplace_back(id, e, l);
        } else if (sec == SVC) {
            int id; double s;
            if (iss >> id >> s) svcs.emplace_back(id, s);
        }
        // DEPOT section: ignored, we always assume depot id == 0
    }
    if (dim <= 0) { std::fprintf(stderr, "ERROR: missing DIMENSION\n"); std::exit(2); }
    inst.nodes.assign(dim, Node{});
    inst.n_customers = dim - 1;
    for (auto& [id, x, y] : coords) {
        if (id < 0 || id >= dim) continue;
        inst.nodes[id].id = id;
        inst.nodes[id].x  = x;
        inst.nodes[id].y  = y;
    }
    for (auto& [id, q]    : demands) if (id >= 0 && id < dim) inst.nodes[id].demand = q;
    for (auto& [id, e, l] : tws)     if (id >= 0 && id < dim) { inst.nodes[id].e = e; inst.nodes[id].l = l; }
    for (auto& [id, s]    : svcs)    if (id >= 0 && id < dim) inst.nodes[id].s = s;
    return inst;
}

static void write_output(const std::string& path, const Solution& sol) {
    std::ofstream out(path);
    if (!out) {
        std::fprintf(stderr, "ERROR: cannot open output file: %s\n", path.c_str());
        std::exit(3);
    }
    out << "Routes: " << sol.routes.size() << "\n";
    for (size_t r = 0; r < sol.routes.size(); ++r) {
        out << "Route " << (r + 1) << ": 0";
        for (int c : sol.routes[r].seq) out << " " << c;
        out << " 0\n";
    }
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.2f", sol.total_cost);
    out << "Cost: " << buf << "\n";
}

// ---------- Solver core ----------

// Simulate route once; returns cost and feasibility.
struct RouteCheck {
    bool feasible;
    double cost;
    int    load;
    double end_time;   // arrival back at depot
};

static RouteCheck check_route(const Instance& inst, const std::vector<int>& seq) {
    RouteCheck rc{true, 0.0, 0, 0.0};
    int prev = 0;
    double t = 0.0;
    for (int c : seq) {
        double d = dist_x10(inst.nodes[prev], inst.nodes[c]);
        rc.cost += d;
        t += d;
        if (t < inst.nodes[c].e) t = inst.nodes[c].e;
        if (t > inst.nodes[c].l + 1e-6) { rc.feasible = false; break; }
        t += inst.nodes[c].s;
        rc.load += inst.nodes[c].demand;
        prev = c;
    }
    if (rc.feasible) {
        double back = dist_x10(inst.nodes[prev], inst.nodes[0]);
        rc.cost += back;
        t       += back;
        if (t > inst.nodes[0].l + 1e-6) rc.feasible = false;
        rc.end_time = t;
    }
    if (rc.load > inst.capacity) rc.feasible = false;
    return rc;
}

// Push-Forward feasibility: try inserting customer c at end of `seq`.
static bool can_append(const Instance& inst, const std::vector<int>& seq,
                       int load, double t_at_prev_end_service, int prev, int c) {
    if (load + inst.nodes[c].demand > inst.capacity) return false;
    double d = dist_x10(inst.nodes[prev], inst.nodes[c]);
    double arr = t_at_prev_end_service + d;
    double start = std::max(arr, inst.nodes[c].e);
    if (start > inst.nodes[c].l + 1e-6) return false;
    double depart = start + inst.nodes[c].s;
    double back = dist_x10(inst.nodes[c], inst.nodes[0]);
    if (depart + back > inst.nodes[0].l + 1e-6) return false;
    return true;
}

static Solution nearest_neighbor(const Instance& inst,
                                 const Clock::time_point& deadline) {
    Solution sol;
    int N = inst.n_customers;
    std::vector<bool> visited(N + 1, false);
    visited[0] = true;
    int remaining = N;
    while (remaining > 0) {
        if (Clock::now() >= deadline) break;
        Route r;
        int prev = 0;
        double t = 0.0;     // departure time from prev
        int load = 0;
        while (true) {
            int best = -1;
            double best_d = std::numeric_limits<double>::infinity();
            for (int c = 1; c <= N; ++c) {
                if (visited[c]) continue;
                if (!can_append(inst, r.seq, load, t, prev, c)) continue;
                double d = dist_x10(inst.nodes[prev], inst.nodes[c]);
                if (d < best_d) { best_d = d; best = c; }
            }
            if (best == -1) break;
            // commit
            double arr   = t + best_d;
            double start = std::max(arr, inst.nodes[best].e);
            t            = start + inst.nodes[best].s;
            load        += inst.nodes[best].demand;
            r.seq.push_back(best);
            visited[best] = true;
            --remaining;
            prev = best;
        }
        if (r.seq.empty()) {
            // safety: avoid infinite loop on pathological inputs
            for (int c = 1; c <= N; ++c) if (!visited[c]) { r.seq.push_back(c); visited[c] = true; --remaining; break; }
        }
        auto rc = check_route(inst, r.seq);
        r.cost = rc.cost;
        r.load = rc.load;
        sol.total_cost += rc.cost;
        sol.routes.push_back(std::move(r));
        if ((int)sol.routes.size() > inst.max_vehicles) break;
    }
    return sol;
}

// ---------- main ----------

int main(int argc, char** argv) {
    if (argc < 4) {
        std::fprintf(stderr, "usage: %s <input> <output> <time_budget_sec>\n", argv[0]);
        return 1;
    }
    auto start = Clock::now();
    int budget = std::atoi(argv[3]);
    if (budget <= 0) budget = 60;
    auto deadline = start + std::chrono::seconds(budget);

    Instance inst = parse_input(argv[1]);
    Solution sol  = nearest_neighbor(inst, deadline);

    // Recompute total cost defensively.
    sol.total_cost = 0.0;
    for (auto& r : sol.routes) sol.total_cost += r.cost;

    write_output(argv[2], sol);
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - start).count();
    std::fprintf(stderr,
                 "[baseline] %s NV=%zu TD=%.2f cpu_ms=%lld\n",
                 inst.name.c_str(), sol.routes.size(), sol.total_cost,
                 (long long)elapsed);
    return 0;
}
