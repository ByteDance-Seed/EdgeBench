# Opt-in diagnostic image. This does not replace an official image tag.
FROM seededge/edgebench.judge.portfolio_risk_calibration:08fe0a4bad80
COPY repair.py /tmp/portfolio-repair.py
RUN python3 /tmp/portfolio-repair.py /home/workspace/scoring/eval_script.py /tmp/eval_script.py \
    && cp /home/workspace/scoring/eval_script.py /tmp/original-eval-script.py \
    && cp /tmp/eval_script.py /home/workspace/scoring/eval_script.py
COPY test_repair.py /tmp/test_repair.py
RUN python3 /tmp/test_repair.py /tmp/original-eval-script.py /home/workspace/scoring/eval_script.py
