# Must be paired with the judge built using EVENT_CONTRACT=1.
FROM seededge/edgebench.work.portfolio_risk_calibration:e9e47d60871d
COPY event_contract.py /home/workspace/event_contract.py
COPY task-contract.md /home/workspace/attachments/portfolio-event-contract-v1.md
RUN printf '\n\n## Experimental event contract v1\n\nRead `attachments/portfolio-event-contract-v1.md` before implementing. It defines this task variant and takes precedence over ambiguous event/trade fields in the older deliverables guide. Public event validation is available through `python3 event_contract.py backtest_results.json trading_dates.json`.\n' >> /home/workspace/task_instruction.md
