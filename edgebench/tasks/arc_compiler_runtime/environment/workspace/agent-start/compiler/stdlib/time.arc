# Arc Standard Library: time module
# Simulated time utilities

pub fn now() => __native("time.now")

pub fn format_duration(ms) {
  let total_s = int(ms / 1000)
  let h = int(total_s / 3600)
  let m = int((total_s % 3600) / 60)
  let s = total_s % 60
  let parts = []
  let mut result = ""
  if h > 0 { result = str(h) ++ "h " }
  if m > 0 { result = result ++ str(m) ++ "m " }
  result = result ++ str(s) ++ "s"
  result
}

pub fn sleep(ms) => __native("time.sleep", ms)
