# Work image for borden_source_inversion (agent workspace).
# Build context = the task directory:
#   sforge build --task borden_source_inversion
#
# v1 work.setup_cmds -> this file:
#   0 apt-get update && apt-get install -y curl unzip        -> dropped (both already in the base, dpkg list unchanged in v1)
#   1 mkdir -p <cwd> /tmp/borden_inverse_bundle               -> implied by COPY below
#   2 curl .../borden_inverse_public_task_bundle.zip (internal object storage, v0.1.0)
#   3 unzip; 4 cp -a bundle/borden_inverse/. <cwd>; 5 rm bundle
#                                                             -> bundle contents committed under environment/workspace/
#                                                                (all 10 files sha256-identical to the published image)
#   6 pip install --no-cache-dir -r requirements.txt          -> pip install --require-hashes of environment/requirements.lock
#                                                                (the 30 exact versions the published image has)
#     && rm -rf scoring private_generation_record_not_for_agent.json score.json
#                                                             -> nothing to remove (the public bundle has none of them)
#   7 rm -rf .git && git init && git config user.* && git add -A && git commit -m 'init'
#                                                             -> same, v1's commit date pinned (gives v1's commit 07208e74)
#   (template) chown -R agent:agent <cwd>; USER agent         -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Python deps from public PyPI, every wheel checked by sha256 (pip --require-hashes).
COPY environment/requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir --require-hashes -r /tmp/requirements.lock \
 && rm /tmp/requirements.lock

COPY environment/workspace/ /home/workspace/borden_inverse/
WORKDIR /home/workspace/borden_inverse
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author/email/message/date = v1's commit 07208e74 (1780754156 = 2026-06-06T13:55:56Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1780754156 +0000" GIT_COMMITTER_DATE="1780754156 +0000" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
