# Arc Standard Library: env module
# Environment variable utilities

pub fn get(key) => __native("env.get", key)
pub fn get_or(key, default) => __native("env.get_or", key, default)
pub fn set(key, val) => __native("env.set", key, val)
pub fn remove(key) => __native("env.remove", key)
pub fn has(key) => __native("env.has", key)
pub fn list() => __native("env.list")
pub fn require(key) => __native("env.require", key)
