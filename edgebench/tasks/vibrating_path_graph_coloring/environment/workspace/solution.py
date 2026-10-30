import sys

def main():
    data = sys.stdin.read().split()
    N, M, K = int(data[0]), int(data[1]), int(data[2])
    # Baseline: 0 hits, color vertex i with (i mod K) + 1
    # Will WA on most cases, but output is well-formed
    print(0)
    print(' '.join([str((i % K) + 1) for i in range(N)]))

main()
