import sys

def main():
    data = sys.stdin.read().split()
    N, T, M, K, L = int(data[0]), int(data[1]), int(data[2]), int(data[3]), int(data[4])
    # Baseline: bond within each K-sized block at time 0
    count = 0
    target = N - M
    for comp in range(M):
        base = comp * K
        for offset in range(1, K):
            if count >= target:
                return
            print(f"0 {base} {base+offset}")
            count += 1

main()
