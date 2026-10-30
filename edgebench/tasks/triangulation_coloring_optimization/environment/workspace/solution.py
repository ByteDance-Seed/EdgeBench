import sys

def main():
    lines = sys.stdin.read().split('\n')
    first = lines[0].split()
    N, M = int(first[0]), int(first[1])
    colors = lines[2].strip()
    print("0 0")
    print(colors)

main()
