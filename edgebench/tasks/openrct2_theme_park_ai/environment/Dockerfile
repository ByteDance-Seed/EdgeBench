# Work image for openrct2_theme_park_ai (agent workspace).
# Build context = the task directory:
#   sforge build --task openrct2_theme_park_ai
#
# v1 work.setup_cmds -> this file:
#   1 mkdir -p /home/workspace/openrct2                      -> implied by COPY below
#   2 curl <internal TOS>/openrct2_work_assets.tar.gz | tar   -> COPY environment/workspace/ (the tarball's 6 files,
#                                                              sha256-identical; mtimes = the tarball's epoch 0)
#   3 git init && git config user.* && git add -A && commit  -> kept, author/dates pinned to v1 (same commit hash)
#   (template) chown -R agent:agent <cwd>; USER agent         -> dropped (root)

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/openrct2/
WORKDIR /home/workspace/openrct2
RUN set -eux; \
    chmod 755 . samples; chmod 644 my_plugin.js openrct2.d.ts samples/*.js; \
    touch -d @0 my_plugin.js openrct2.d.ts samples samples/*.js; \
    git init -q; git config user.email 'sebench@local'; git config user.name 'sebench'; git add -A; \
    GIT_AUTHOR_DATE="2026-06-10T14:16:42+00:00" GIT_COMMITTER_DATE="2026-06-10T14:16:42+00:00" git commit -m 'init' -q; \
    test "$(git rev-parse HEAD)" = 0290fc2695fd39ec929eb83163bc15d8ed423783
CMD ["python3"]
