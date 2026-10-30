#include <bits/stdc++.h>
using namespace std;

typedef long long ll;
typedef pair<ll,ll> pll;

ll cross(pll o, pll a, pll b) {
    return (a.first-o.first)*(b.second-o.second) - (a.second-o.second)*(b.first-o.first);
}

bool on_segment(pll p, pll q, pll r) {
    return min(p.first,r.first) <= q.first && q.first <= max(p.first,r.first) &&
           min(p.second,r.second) <= q.second && q.second <= max(p.second,r.second);
}

bool segments_intersect(pll p1, pll p2, pll p3, pll p4) {
    ll d1 = cross(p3,p4,p1), d2 = cross(p3,p4,p2);
    ll d3 = cross(p1,p2,p3), d4 = cross(p1,p2,p4);
    if (((d1>0&&d2<0)||(d1<0&&d2>0)) && ((d3>0&&d4<0)||(d3<0&&d4>0))) return true;
    if (d1==0 && on_segment(p3,p1,p4)) return true;
    if (d2==0 && on_segment(p3,p2,p4)) return true;
    if (d3==0 && on_segment(p1,p3,p2)) return true;
    if (d4==0 && on_segment(p1,p4,p2)) return true;
    return false;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: ./tester <input_file> <output_file>\n");
        return 1;
    }

    FILE* fin = fopen(argv[1], "r");
    if (!fin) { fprintf(stderr, "wrong answer: cannot open input\n"); return 1; }

    int N, M;
    fscanf(fin, "%d %d", &N, &M);

    vector<ll> cx(N), cy(N);
    for (int i = 0; i < N; i++) fscanf(fin, "%lld %lld", &cx[i], &cy[i]);

    vector<ll> wa(M), wb(M), wc(M), wd(M);
    for (int i = 0; i < M; i++) fscanf(fin, "%lld %lld %lld %lld", &wa[i], &wb[i], &wc[i], &wd[i]);
    fclose(fin);

    FILE* fout = fopen(argv[2], "r");
    if (!fout) { fprintf(stderr, "wrong answer: cannot open output\n"); return 1; }

    vector<ll> h(M), v(M);
    ll Q = 0;
    for (int i = 0; i < M; i++) {
        if (fscanf(fout, "%lld %lld", &h[i], &v[i]) != 2) {
            fprintf(stderr, "wrong answer: expected %d lines of h v\n", M);
            return 1;
        }
        if (abs(h[i]) > 1000000 || abs(v[i]) > 1000000) {
            fprintf(stderr, "wrong answer: move values out of range on line %d\n", i+1);
            return 1;
        }
        Q += h[i]*h[i] + v[i]*v[i];
    }
    fclose(fout);

    // Apply moves
    vector<pll> seg_a(M), seg_b(M);
    for (int i = 0; i < M; i++) {
        seg_a[i] = {wa[i]+h[i], wb[i]+v[i]};
        seg_b[i] = {wc[i]+h[i], wd[i]+v[i]};
    }

    // Plates
    pll pos_p1 = {-1, 0}, pos_p2 = {0, -1};
    pll neg_p1 = {1000001, 1000000}, neg_p2 = {1000000, 1000001};

    vector<bool> is_pos(M, false), is_neg(M, false);

    // Check direct plate intersections
    for (int i = 0; i < M; i++) {
        if (segments_intersect(seg_a[i], seg_b[i], pos_p1, pos_p2)) is_pos[i] = true;
        if (segments_intersect(seg_a[i], seg_b[i], neg_p1, neg_p2)) is_neg[i] = true;
    }

    // Build wire-wire intersection graph
    vector<vector<int>> adj(M);
    for (int i = 0; i < M; i++) {
        for (int j = i+1; j < M; j++) {
            if (segments_intersect(seg_a[i], seg_b[i], seg_a[j], seg_b[j])) {
                adj[i].push_back(j);
                adj[j].push_back(i);
            }
        }
    }

    // BFS positive
    {
        queue<int> q;
        for (int i = 0; i < M; i++) if (is_pos[i]) q.push(i);
        while (!q.empty()) {
            int u = q.front(); q.pop();
            for (int v : adj[u]) {
                if (!is_pos[v]) { is_pos[v] = true; q.push(v); }
            }
        }
    }

    // BFS negative
    {
        queue<int> q;
        for (int i = 0; i < M; i++) if (is_neg[i]) q.push(i);
        while (!q.empty()) {
            int u = q.front(); q.pop();
            for (int v : adj[u]) {
                if (!is_neg[v]) { is_neg[v] = true; q.push(v); }
            }
        }
    }

    // Validity checks
    bool has_pos = false, has_neg = false, short_circuit = false;
    for (int i = 0; i < M; i++) {
        if (is_pos[i]) has_pos = true;
        if (is_neg[i]) has_neg = true;
        if (is_pos[i] && is_neg[i]) short_circuit = true;
    }
    if (!has_pos) { fprintf(stderr, "wrong answer: no positive wire\n"); return 1; }
    if (!has_neg) { fprintf(stderr, "wrong answer: no negative wire\n"); return 1; }
    if (short_circuit) { fprintf(stderr, "wrong answer: short circuit\n"); return 1; }

    // Collect endpoints
    vector<pll> pos_eps, neg_eps;
    for (int i = 0; i < M; i++) {
        if (is_pos[i]) { pos_eps.push_back(seg_a[i]); pos_eps.push_back(seg_b[i]); }
        if (is_neg[i]) { neg_eps.push_back(seg_a[i]); neg_eps.push_back(seg_b[i]); }
    }

    // Compute P
    ll P = 0;
    for (int i = 0; i < N; i++) {
        ll min_s = LLONG_MAX, min_t = LLONG_MAX;
        for (auto& [px, py] : pos_eps) {
            ll d = (cx[i]-px)*(cx[i]-px) + (cy[i]-py)*(cy[i]-py);
            if (d < min_s) min_s = d;
        }
        for (auto& [px, py] : neg_eps) {
            ll d = (cx[i]-px)*(cx[i]-px) + (cy[i]-py)*(cy[i]-py);
            if (d < min_t) min_t = d;
        }
        P += min_s + min_t;
    }

    ll total = P + Q;
    fprintf(stderr, "Score = %lld\n", total);
    return 0;
}
