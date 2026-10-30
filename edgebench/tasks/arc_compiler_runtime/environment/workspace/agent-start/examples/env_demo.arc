use env

print("=== Env Module Demo ===")
print("PATH exists: " ++ str(env.has("PATH")))
print("HOME: " ++ str(env.get("HOME")))
print("MISSING: " ++ str(env.get("ARC_NONEXISTENT_VAR")))
print("MISSING with default: " ++ env.get_or("ARC_NONEXISTENT_VAR", "fallback_value"))

env.set("ARC_TEST_VAR", "hello_arc")
print("After set: " ++ str(env.get("ARC_TEST_VAR")))
print("has ARC_TEST_VAR: " ++ str(env.has("ARC_TEST_VAR")))

env.remove("ARC_TEST_VAR")
print("After remove: " ++ str(env.get("ARC_TEST_VAR")))

print("Env var count: " ++ str(len(env.list())))
