use path

print("=== Path Module Demo ===")
print("sep: " ++ path.sep())
print("join: " ++ path.join("usr", "local", "bin"))
print("dirname: " ++ path.dirname("/usr/local/bin/node"))
print("basename: " ++ path.basename("/usr/local/bin/node"))
print("extname: " ++ path.extname("archive.tar.gz"))
print("normalize: " ++ path.normalize("/usr/local/../bin/./node"))
print("is_absolute /usr: " ++ str(path.is_absolute("/usr")))
print("is_absolute relative: " ++ str(path.is_absolute("relative/path")))
print("resolve .: " ++ path.resolve("."))
