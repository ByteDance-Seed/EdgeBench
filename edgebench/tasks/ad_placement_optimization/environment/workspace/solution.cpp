// Baseline solution for AHC001 - AtCoder Ad.
// Places a 1x1 rectangle at each requested point. This is intentionally simple
// but always produces a valid, compilable submission for the initial workspace.
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n;
    if (!(cin >> n)) return 0;
    for (int i = 0; i < n; ++i) {
        int x, y, r;
        cin >> x >> y >> r;
        (void)r;
        cout << x << ' ' << y << ' ' << x + 1 << ' ' << y + 1 << '\n';
    }
    return 0;
}
