# Judge / game-server image for anchorhead_text_adventure.
# Build context = the task directory:
#   sforge build --task anchorhead_text_adventure
#
# Game mode: the harness starts one container of this image per game session,
# copies its own game_server_app.py to /opt/sforge/game_server_app.py and runs
# task.toml [game].server_cmd (jericho + fastapi + uvicorn, ROM below).
#
# v1 judge.setup_cmds -> this file:
#   1 pip install --no-cache-dir jericho fastapi uvicorn      -> hash-locked judge/requirements.txt (same versions)
#   2 mkdir -p /home/roms                                     -> RUN below
#   3 git clone --depth 1 github.com/foreverpiano/z-machine-games /tmp/z-machine-games
#   4 find ... -name anchor.z8 -exec cp {} /home/roms/        -> pinned raw download of the same file + sha256 check
#   5 rm -rf /tmp/z-machine-games                             -> nothing to remove
#   (workdir) /home/jericho_agent                             -> RUN mkdir + WORKDIR

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY judge/requirements.txt /judge/requirements.txt
# --no-build-isolation: jericho's setup.py (sdist) builds with the base's
# setuptools 79.0.1, as v1 did (its WHEEL says "Generator: setuptools (79.0.1)").
RUN pip install --no-cache-dir --require-hashes --no-deps --no-build-isolation \
      -r /judge/requirements.txt

# anchor.z8 (Anchorhead, Michael S. Gentry, 1998; Z-machine v8) from
# foreverpiano/z-machine-games @ bfd7544aa1f5 (HEAD, 2018-10-30), path jericho-game-suite/anchor.z8.
ARG ROM_URL=https://raw.githubusercontent.com/foreverpiano/z-machine-games/bfd7544aa1f50549fc327bd4eb3bc8144bfd80ea/jericho-game-suite/anchor.z8
RUN set -eux; mkdir -p /home/roms; \
    curl -fsSL -o /home/roms/anchor.z8 "$ROM_URL"; \
    echo "c2f28a4ddd9367c260946926a33c73a4b0cc38b1f327646cc1202182a28a10ff  /home/roms/anchor.z8" | sha256sum -c -; \
    chmod 644 /home/roms/anchor.z8

RUN mkdir -p /home/jericho_agent
WORKDIR /home/jericho_agent
CMD ["python3"]
