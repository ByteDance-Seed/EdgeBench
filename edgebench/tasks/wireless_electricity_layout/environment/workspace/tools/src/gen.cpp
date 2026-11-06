#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: ./gen <seed>\n");
        return 1;
    }
    int seed = atoi(argv[1]);
    mt19937 rng(seed);

    int N = 10000, M = 2500;
    int L_vals[] = {8000, 10000, 12000, 14000, 16000};
    int L = L_vals[seed % 5];
    int COORD_MAX = 1000000;

    printf("%d %d\n", N, M);

    for (int i = 0; i < N; i++) {
        int x = rng() % (COORD_MAX + 1);
        int y = rng() % (COORD_MAX + 1);
        printf("%d %d\n", x, y);
    }

    for (int i = 0; i < M; i++) {
        int h = (int)(rng() % (2*L+1)) - L;
        int v = (int)(rng() % (2*L+1)) - L;
        int a_lo = max(0, -h);
        int a_hi = min(COORD_MAX, COORD_MAX + h);
        if (a_lo > a_hi) { a_lo = 0; a_hi = COORD_MAX; }
        int A = a_lo + rng() % (a_hi - a_lo + 1);
        int b_lo = max(0, -v);
        int b_hi = min(COORD_MAX, COORD_MAX + v);
        if (b_lo > b_hi) { b_lo = 0; b_hi = COORD_MAX; }
        int B = b_lo + rng() % (b_hi - b_lo + 1);
        int C = A + h;
        int D = B + v;
        printf("%d %d %d %d\n", A, B, C, D);
    }
    return 0;
}
