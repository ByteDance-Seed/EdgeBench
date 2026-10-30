#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int N, M;
    if (!(cin >> N >> M)) return 0;

    for (int i = 0; i < N; i++) {
        int x, y;
        cin >> x >> y;
    }

    vector<array<int, 4>> wires(M);
    for (int i = 0; i < M; i++) {
        int a, b, c, d;
        cin >> a >> b >> c >> d;
        wires[i] = {a, b, c, d};
    }

    long long h0 = -1LL - wires[0][0];
    long long v0 = -1LL * wires[0][1];
    long long h1 = 1000001LL - wires[1][0];
    long long v1 = 1000000LL - wires[1][1];

    for (int i = 0; i < M; i++) {
        if (i == 0) {
            cout << h0 << ' ' << v0 << '\n';
        } else if (i == 1) {
            cout << h1 << ' ' << v1 << '\n';
        } else {
            cout << "0 0\n";
        }
    }

    return 0;
}
