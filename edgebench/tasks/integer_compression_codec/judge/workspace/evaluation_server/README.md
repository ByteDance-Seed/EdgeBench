# Remote Evaluation Service (Integer Compression)

## Deployment Steps

```bash
# 1. Build the two images
cp ../../workspace/include/intcompress.h ./intcompress.h   # copy ABI header
docker build -t intcompress-server -f Dockerfile .
docker build -t intcompress-runner:latest -f intcompress-runner.Dockerfile .

# 2. Prepare the remote data (run once per machine)
mkdir -p /srv/intcompress/data /var/lib/intcompress
python3 ../../workspace/tools/gen_data.py --full --out-dir /srv/intcompress/data
cp ../baseline/baseline_results.json /srv/intcompress/baseline.json
chmod 0400 /srv/intcompress/data/*.u32

# 3. Start the service
docker run -d --name intcompress-server \
    -p 8080:8080 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /srv/intcompress:/srv/intcompress:ro \
    -v /var/lib/intcompress:/var/lib/intcompress \
    intcompress-server
```

## API

### `POST /submit`

Request: `multipart/form-data`, `file` is a `.tar.gz` (containing `Makefile`, `include/`, `src/`); the `X-Agent-Token` header is used to count submissions.

Response: `{"submission_id": "...", "status": "queued"}`

### `GET /result/{submission_id}`

Poll; when finished, returns the full result JSON with the structure:

```json
{
  "id": "...",
  "status": "done",
  "total_score": 12.345678,
  "per_dataset": [
    {"name": "docids", "weight": 2.0, "n": 100000000, "encoded_bytes": 48750000,
     "encode_ms": 3200.5, "decode_ms": 420.1, "decode_gbps": 11.8,
     "roundtrip_ok": true, "score": 5.36, "error": null},
    ...
  ],
  "compile_log": "...",
  "runtime_log": "..."
}
```

### `GET /leaderboard/{agent_token}`

Returns the highest-scoring `done` submission of this Agent as `final_score`, and lists the top 20.

## Security Properties

- `--network=none --read-only --cap-drop=ALL`; `ptrace` and `perf` are forbidden.
- Datasets are bind-mounted with `0400` permissions at a randomized path (changed for every submission) to prevent the Agent from locating the data by path enumeration.
- `encode` and `decode` run in two separate processes; encode output is written only to a temporary tmpfs directory, and the decode process has **read-only** access to that directory and the original input.
- After compilation, the submitted `libintcompress.so` goes through a symbol allowlist check (`nm -D -u`); any symbol such as `dlopen`/`system`/`fork`/`exec`/`ptrace`/`socket`/`connect`/`open`/`openat` is rejected.
- Compilation is capped at 5 minutes; each dataset is capped at 300 seconds.
- Each Agent token has a cumulative cap of 100 submissions (429 returned once hit).
- Results are written to an exclusive directory with atomic renames, so polling the same submission_id never observes a partial result.

## Operations Notes

- Every submission gets an isolated working directory `/var/lib/intcompress/work/{submission_id}`, cleaned up automatically on completion.
- The JSON files under `RESULT_DIR` keep the full run logs; rotate them periodically to avoid disk bloat.
- When updating the datasets, always re-run the baseline and update `/srv/intcompress/baseline.json`, otherwise `S_i` of already-submitted results will be distorted.
