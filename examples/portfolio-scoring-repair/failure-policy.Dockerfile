# Explicit opt-in image; never overwrite an official or active experiment tag.
ARG BASE_IMAGE=seededge/edgebench.judge.portfolio_risk_calibration:08fe0a4bad80
FROM ${BASE_IMAGE}
COPY failure_policy.py test_failure_policy.py /tmp/portfolio-failure-policy/
RUN python3 /tmp/portfolio-failure-policy/test_failure_policy.py \
      /home/workspace/scoring/scorer_manifest.json /home/workspace/scoring/score.py \
    && python3 /tmp/portfolio-failure-policy/failure_policy.py \
      /home/workspace/scoring/scorer_manifest.json /home/workspace/scoring/score.py \
      /tmp/portfolio-manifest-repaired.json \
    && cp /home/workspace/scoring/scorer_manifest.json /tmp/portfolio-manifest-original.json \
    && cp /tmp/portfolio-manifest-repaired.json /home/workspace/scoring/scorer_manifest.json
