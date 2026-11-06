import sys

def main():
    data = sys.stdin.read().split()
    N = int(data[0])
    # Baseline: 1 color, 1 state, 0 rules, grid all 0
    print("1 1 0")
    for _ in range(N):
        print(' '.join(['0']*N))

main()
