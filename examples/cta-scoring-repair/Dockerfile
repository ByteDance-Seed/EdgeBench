FROM seededge/edgebench.judge.cta_risk_budget_optimization@sha256:e97f3daf7b0ee2c97fcd38c7dab6cb08efc0fe501bb96edf3b80cf204061ff33

USER root
COPY repair.py verify.py verify_inputs.py /tmp/cta-repair/
COPY cta_process.py /home/workspace/scoring/cta_process.py
RUN python3 /tmp/cta-repair/verify_inputs.py /home/workspace/scoring/run_eval.py /home/workspace/scoring/eval_script.py \
    && python3 /tmp/cta-repair/repair.py /home/workspace/scoring/run_eval.py /home/workspace/scoring/eval_script.py /tmp/cta-repair/repaired.py \
    && cp /tmp/cta-repair/repaired.py /home/workspace/scoring/run_eval.py \
    && chmod 0444 /home/workspace/scoring/run_eval.py /home/workspace/scoring/cta_process.py \
    && python3 /tmp/cta-repair/verify.py /home/workspace/scoring/run_eval.py -v \
    && rm -rf /tmp/cta-repair
