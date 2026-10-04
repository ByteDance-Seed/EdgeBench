# Opt-in diagnostic image. This does not replace an official image tag.
FROM seededge/edgebench.judge.portfolio_risk_calibration:08fe0a4bad80
COPY repair.py /tmp/portfolio-repair.py
RUN python3 /tmp/portfolio-repair.py /home/workspace/scoring/eval_script.py /tmp/eval_script.py \
    && cp /home/workspace/scoring/eval_script.py /tmp/original-eval-script.py \
    && cp /tmp/eval_script.py /home/workspace/scoring/eval_script.py
COPY test_repair.py /tmp/test_repair.py
RUN python3 /tmp/test_repair.py /tmp/original-eval-script.py /home/workspace/scoring/eval_script.py

# Explicitly opt into revised task semantics only with the matching work image.
ARG EVENT_CONTRACT=0
COPY event_contract.py /tmp/event_contract.py
COPY test_event_contract.py /tmp/test_event_contract.py
COPY test_event_judge.py /tmp/test_event_judge.py
RUN if [ "$EVENT_CONTRACT" = 1 ]; then \
      python3 /tmp/portfolio-repair.py --event-contract-v1 /tmp/original-eval-script.py /tmp/event-eval-script.py \
      && cp /tmp/event-eval-script.py /home/workspace/scoring/eval_script.py \
      && python3 /tmp/test_event_contract.py \
      && python3 /tmp/test_event_judge.py /home/workspace/scoring/eval_script.py; \
    elif [ "$EVENT_CONTRACT" != 0 ]; then exit 2; fi
