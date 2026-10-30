import sys

def main():
    data = sys.stdin.read().split()
    N, L, T, K = int(data[0]), int(data[1]), int(data[2]), int(data[3])
    # Baseline: do nothing for T turns
    for _ in range(T):
        print(-1)

main()
