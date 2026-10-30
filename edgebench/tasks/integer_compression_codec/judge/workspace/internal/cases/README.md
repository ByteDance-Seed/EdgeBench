# Remote Evaluation Data Directory (generated after machine deployment)

At hand-off from the task authors this directory **contains no actual data files** — the evaluation machine generates them in place at deployment time with the following commands (seeds are fixed, fully reproducible):

```bash
cd /srv/intcompress
python3 /path/to/integer-compression-codec/workspace/tools/gen_data.py --full --out-dir ./data
chmod 0400 ./data/*.u32
```

After generation it should contain:

```
/srv/intcompress/data/
    docids.u32   400 MB
    ts_sec.u32   200 MB
    ts_ns.u32    200 MB
    temp.u32     200 MB
    grid.u32     200 MB
    zipf.u32     200 MB
    rand.u32     200 MB
    sparse.u32   200 MB
```

The SHA-256 of every file is published together with each update of `SPECIFICATION.md §3`.

**Compliance note**: all data is produced by deterministic public scripts; no real user data or copyrighted corpora are used.
