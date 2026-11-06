use log

# Basic logging at all levels
log.info("=== Basic Logging ===")
log.debug("this is a debug message")
log.info("this is an info message")
log.warn("this is a warning message")
log.error("this is an error message")

# Set level to warn — debug and info should be filtered
log.info("=== Setting level to warn ===")
log.set_level("warn")
log.debug("you should NOT see this debug")
log.info("you should NOT see this info")
log.warn("you SHOULD see this warn")
log.error("you SHOULD see this error")

# Reset to debug
log.set_level("debug")
log.info("=== Child Logger ===")

# Child logger with context fields
let logger = log.with({"service": "api", "request_id": "abc-123"})
log.child_info(logger, "handling request")
log.child_warn(logger, "slow query detected")

# JSON structured output
log.info("=== JSON Output ===")
log.json("info", "user logged in", {"user": "alice", "ip": "10.0.0.1"})
log.json("error", "db connection failed", {"host": "db01", "retries": 3})

log.info("=== Done ===")
