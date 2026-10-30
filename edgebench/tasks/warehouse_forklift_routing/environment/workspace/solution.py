import sys

def main():
    data = sys.stdin.read().split()
    idx = 0
    T = int(data[idx]); idx += 1
    for _ in range(T):
        R = int(data[idx]); C = int(data[idx+1]); idx += 2
        idx += R * C - 1
        print('')

main()
