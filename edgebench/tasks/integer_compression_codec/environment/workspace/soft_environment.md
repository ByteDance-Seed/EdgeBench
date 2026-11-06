# Software Environment

The provided directory is `workspace/`, which contains:

1. `README.md`: Public task description, build instructions, local verification and debugging methods.
2. `include/intcompress.h`: Fixed ABI contract, declaring three exported functions: `ic_encode`, `ic_decode`, `ic_decode_block`.
3. `src/codec.cpp`: A compilable, runnable public starter baseline, serving as the implementation starting point.
4. `Makefile`: Builds `libintcompress.so` and local tools.
5. `tools/gen_data.py`: Generates public small-sample data.
6. `tools/bench.cpp`: Local performance benchmarking tool.
7. `tools/verify.cpp`: Local correctness verification tool.
8. `datasets/`: Public small-sample data directory description.

The agent is free to modify the implementation under `src/` and add private header files or source files, but must keep the ABI of `include/intcompress.h` unchanged.

The local workspace only provides the public starter; it does not include hidden data, evaluation services, or private reference implementations. Official evaluation will be performed in a separate environment.
