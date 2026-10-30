# Arc Standard Library: datetime module
# Comprehensive date and time utilities

# Constants
let MS_PER_MINUTE = 60000
let MS_PER_HOUR = 3600000
let MS_PER_DAY = 86400000

# Returns the current timestamp in milliseconds since Unix epoch
pub fn now() => __builtin_now()

# Returns today's date as a map {year, month, day}
pub fn today() {
  let ts = now()
  let days = int(ts / MS_PER_DAY)
  __builtin_date_from_ts(ts)
}

# Parse a date string with the given format to a timestamp
# Format tokens: YYYY, MM, DD, hh, mm, ss
pub fn parse(date_string, format) => __builtin_date_parse(date_string, format)

# Format a timestamp to a string using the given format
# Format tokens: YYYY, MM, DD, hh, mm, ss
pub fn format(timestamp, format_string) => __builtin_date_format(timestamp, format_string)

# Add days to a timestamp, returns new timestamp
pub fn add_days(timestamp, days) => timestamp + days * MS_PER_DAY

# Add hours to a timestamp, returns new timestamp
pub fn add_hours(timestamp, hours) => timestamp + hours * MS_PER_HOUR

# Add minutes to a timestamp, returns new timestamp
pub fn add_minutes(timestamp, minutes) => timestamp + minutes * MS_PER_MINUTE

# Difference in days between two timestamps (absolute value)
pub fn diff_days(ts1, ts2) {
  let diff = ts1 - ts2
  let abs_diff = if diff < 0 { 0 - diff } el { diff }
  int(abs_diff / MS_PER_DAY)
}

# Difference in hours between two timestamps (absolute value)
pub fn diff_hours(ts1, ts2) {
  let diff = ts1 - ts2
  let abs_diff = if diff < 0 { 0 - diff } el { diff }
  int(abs_diff / MS_PER_HOUR)
}

# Difference in minutes between two timestamps (absolute value)
pub fn diff_minutes(ts1, ts2) {
  let diff = ts1 - ts2
  let abs_diff = if diff < 0 { 0 - diff } el { diff }
  int(abs_diff / MS_PER_MINUTE)
}

# Returns the day of the week (0 = Sunday, 6 = Saturday)
pub fn day_of_week(timestamp) {
  # Jan 1 1970 was a Thursday (4)
  let days = int(timestamp / MS_PER_DAY)
  let result = ((days + 4) % 7 + 7) % 7
  result
}

# Returns true if ts1 is before ts2
pub fn is_before(ts1, ts2) => ts1 < ts2

# Returns true if ts1 is after ts2
pub fn is_after(ts1, ts2) => ts1 > ts2

# Convert a timestamp to an ISO 8601 string
pub fn to_iso(timestamp) => __builtin_date_to_iso(timestamp)

# Parse an ISO 8601 string to a timestamp
pub fn from_iso(iso_string) => __builtin_date_from_iso(iso_string)
