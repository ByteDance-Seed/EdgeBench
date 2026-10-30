# Arc Standard Library: path module
# Path manipulation utilities

pub fn join(...parts) => __native("path.join_list", parts)
pub fn dirname(p) => __native("path.dirname", p)
pub fn basename(p) => __native("path.basename", p)
pub fn extname(p) => __native("path.extname", p)
pub fn resolve(p) => __native("path.resolve", p)
pub fn normalize(p) => __native("path.normalize", p)
pub fn is_absolute(p) => __native("path.is_absolute", p)
pub fn sep() => __native("path.sep")
