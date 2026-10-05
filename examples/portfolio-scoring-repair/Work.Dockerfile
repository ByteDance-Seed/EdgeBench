# Must be paired with the judge built using EVENT_CONTRACT=1.
FROM seededge/edgebench.work.portfolio_risk_calibration:e9e47d60871d
COPY event_contract.py /home/workspace/event_contract.py
COPY task-contract.md /home/workspace/attachments/portfolio-event-contract-v1.md
RUN printf '\n\n## Experimental event contract v1\n\nRead `attachments/portfolio-event-contract-v1.md` before implementing. It defines this task variant and takes precedence over ambiguous event/trade fields in the older deliverables guide. Public event validation is available through `python3 event_contract.py backtest_results.json trading_dates.json`.\n' >> /home/workspace/task_instruction.md

ARG LEDGER_CONTRACT=0
COPY ledger_contract.py ledger-contract.md /tmp/
RUN if [ "$LEDGER_CONTRACT" = 1 ]; then \
      cp /tmp/ledger_contract.py /home/workspace/ledger_contract.py \
      && cp /tmp/ledger-contract.md /home/workspace/attachments/portfolio-ledger-v2.md \
      && printf '\n\n## Experimental ledger v2\nRead `attachments/portfolio-ledger-v2.md` before implementing. It takes precedence for accounting, costs and output fields over event v1 and the legacy guide. Every daily balance must reconcile. Both feedback arms have `python3 ledger_contract.py RESULTS PUBLIC_PRICES_CSV`; this is local public validation, not judge feedback.\n' >> /home/workspace/task_instruction.md; \
    elif [ "$LEDGER_CONTRACT" != 0 ]; then exit 2; fi

ARG VAR_TIMING=0
COPY var-timing-contract.md /tmp/
RUN if [ "$VAR_TIMING" = 1 ] && [ "$LEDGER_CONTRACT" = 1 ]; then \
      cp /tmp/var-timing-contract.md /home/workspace/attachments/portfolio-var-timing-v1.md \
      && printf '\n\n## Experimental VaR timing v1\nRead `attachments/portfolio-var-timing-v1.md`. Independent VaR uses the preceding session close holdings for the following close-to-close NAV return. All other ledger-v2 and scoring rules remain unchanged.\n' >> /home/workspace/task_instruction.md; \
    elif [ "$VAR_TIMING" != 0 ]; then exit 2; fi
