# Arc Standard Library: os module
# Filesystem and system operations

# Returns the current working directory
pub fn cwd() => __native("os.cwd")

# Get environment variable by name, returns nil if not set
pub fn get_env(name) => __native("os.env", name)

# Alias for get_env
pub fn env(name) => __native("os.env", name)

# Set environment variable
pub fn set_env(name, value) => __native("os.set_env", name, value)

# List files and directories in the given path, returns a list of strings
pub fn list_dir(path) => __native("os.list_dir", path)

# Check if path points to a file
pub fn is_file(path) => __native("os.is_file", path)

# Check if path points to a directory
pub fn is_dir(path) => __native("os.is_dir", path)

# Create a directory (and parent directories if needed)
pub fn mkdir(path) => __native("os.mkdir", path)

# Remove an empty directory
pub fn rmdir(path) => __native("os.rmdir", path)

# Remove a file
pub fn remove(path) => __native("os.remove", path)

# Rename or move a file/directory
pub fn rename(old_path, new_path) => __native("os.rename", old_path, new_path)

# Copy a file from src to dest
pub fn copy(src, dest) => __native("os.copy", src, dest)

# Get file size in bytes
pub fn file_size(path) => __native("os.file_size", path)

# Get file extension (e.g. ".txt"), returns "" if none
pub fn file_ext(path) {
  let parts = split(path, ".")
  if len(parts) <= 1 { "" }
  el { "." ++ last(parts) }
}

# Join path segments with the platform separator
pub fn join_path(parts) {
  let sep = if platform() == "windows" { "\\" } el { "/" }
  join(parts, sep)
}

# Get the parent directory of a path
pub fn parent_dir(path) {
  let sep = if platform() == "windows" { "\\" } el { "/" }
  let parts = split(path, sep)
  if len(parts) <= 1 { "." }
  el {
    let parent_parts = slice(parts, 0, len(parts) - 1)
    join(parent_parts, sep)
  }
}

# Get the filename (basename) from a path
pub fn basename(path) {
  let sep = if platform() == "windows" { "\\" } el { "/" }
  let parts = split(path, sep)
  last(parts)
}

# Execute a shell command and return its output as a string
pub fn exec(command) => __native("os.exec", command)

# Returns the platform: "windows", "linux", or "macos"
pub fn platform() => __native("os.platform")

# Returns the user's home directory
pub fn home_dir() => __native("os.home_dir")

# Returns the system temp directory
pub fn temp_dir() => __native("os.temp_dir")
