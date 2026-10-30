# Package Registry
# Demonstrates: maps, mutation, version parsing, pipelines

let mut packages = {}

fn publish(name, version, deps) {
  let existing = if packages[name] != nil { packages[name] } el { {versions: []} }
  let new_version = {version: version, deps: deps, published: time_ms()}
  existing.versions = push(existing.versions, new_version)
  packages[name] = existing
}

fn get_latest(name) {
  let pkg = packages[name]
  if pkg == nil { ret Err("Package not found: {name}") }
  if len(pkg.versions) == 0 { ret Err("No versions") }
  Ok(last(pkg.versions))
}

fn list_versions(name) {
  let pkg = packages[name]
  if pkg == nil { ret [] }
  pkg.versions |> map(v => v.version)
}

fn search(query) {
  let all_names = keys(packages)
  all_names |> filter(name => contains(name, query))
}

fn resolve_deps(name) {
  let result = get_latest(name)
  if is_err(result) { ret [] }
  let pkg = unwrap(result)
  let mut all_deps = []
  for dep in pkg.deps {
    all_deps = push(all_deps, dep)
    let transitive = resolve_deps(dep)
    for t in transitive {
      if not contains(all_deps, t) {
        all_deps = push(all_deps, t)
      }
    }
  }
  all_deps
}

# Demo
print("=== Package Registry ===")

publish("arc-core", "0.1.0", [])
publish("arc-core", "0.2.0", [])
publish("arc-http", "1.0.0", ["arc-core"])
publish("arc-json", "1.0.0", ["arc-core"])
publish("arc-web", "1.0.0", ["arc-http", "arc-json"])
publish("arc-cli", "0.5.0", ["arc-core", "arc-json"])

print("arc-core versions: {list_versions("arc-core")}")
print("arc-web versions: {list_versions("arc-web")}")

let latest = get_latest("arc-web")
if is_ok(latest) {
  let pkg = unwrap(latest)
  print("Latest arc-web: {pkg.version}")
  print("  Direct deps: {pkg.deps}")
}

print("All deps for arc-web: {resolve_deps("arc-web")}")
print("All deps for arc-cli: {resolve_deps("arc-cli")}")

let results = search("arc")
print("Search 'arc': {results}")

let not_found = get_latest("nonexistent")
print("Not found: {is_err(not_found)}")
