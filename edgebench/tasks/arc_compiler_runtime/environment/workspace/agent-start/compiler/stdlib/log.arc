# Arc Standard Library: log module
# Structured logging with levels and colors

pub fn debug(msg) => __native("log.emit", "debug", msg, nil)
pub fn info(msg) => __native("log.emit", "info", msg, nil)
pub fn warn(msg) => __native("log.emit", "warn", msg, nil)
pub fn error(msg) => __native("log.emit", "error", msg, nil)
pub fn fatal(msg) => __native("log.fatal", msg)

pub fn set_level(level) => __native("log.set_level", level)

pub fn with(fields) => __native("log.with", fields)

pub fn json(level, msg, fields) => __native("log.json", level, msg, fields)

# Child logger helpers — call these on the map returned by with()
pub fn child_debug(logger, msg) => __native("log.emit", "debug", msg, logger)
pub fn child_info(logger, msg) => __native("log.emit", "info", msg, logger)
pub fn child_warn(logger, msg) => __native("log.emit", "warn", msg, logger)
pub fn child_error(logger, msg) => __native("log.emit", "error", msg, logger)
