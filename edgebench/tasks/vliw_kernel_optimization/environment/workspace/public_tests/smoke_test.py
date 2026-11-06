import os
import subprocess
import sys


def main():
    workspace_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cmd = [sys.executable, "runner.py"]
    subprocess.run(cmd, cwd=workspace_dir, check=True)


if __name__ == "__main__":
    main()
