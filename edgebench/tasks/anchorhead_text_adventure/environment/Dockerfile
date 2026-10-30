# Work image for anchorhead_text_adventure (agent workspace; game mode).
# Build context = the task directory:
#   sforge build --task anchorhead_text_adventure
#
# v1 work.setup_cmds -> this file:
#   1 mkdir -p /home/jericho_agent                     -> RUN mkdir below
#   (template) chown -R agent:agent <cwd>; USER agent  -> dropped (root)
# The workspace is empty: the agent plays through the game HTTP API
# (GAME_SERVER_URL, set by the harness), not by editing files.

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
RUN mkdir -p /home/jericho_agent
WORKDIR /home/jericho_agent
CMD ["python3"]
