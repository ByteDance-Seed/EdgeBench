## What and why

<!-- Link the issue this addresses (Fixes #...). -->

## Checklist for task changes

- [ ] `version` in `task.toml` is bumped (any change that can move scores).
- [ ] `NOTES.md`: the change and its score effect are under **Changes**, and the fixed entry is removed from **Known issues**.
- [ ] Old vs new judge on the same submissions, on the same host, results below
      (`tools/judge_local.py --image <old judge tag>`; timed graders at least twice each).
- [ ] New blobs, if any, are uploaded to the `task-blobs` Release.

## Old vs new judge

| Submission | Old | New |
|------------|-----|-----|
