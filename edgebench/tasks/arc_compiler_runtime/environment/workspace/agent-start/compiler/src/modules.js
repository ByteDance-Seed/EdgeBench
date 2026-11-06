const modules = {
  math: { ...Math, PI: Math.PI, E: Math.E, pow: Math.pow, sqrt: Math.sqrt, ceil: Math.ceil, floor: Math.floor, clamp: (x, a, b) => Math.min(b, Math.max(a, x)) },
  strings: { capitalize: (s) => String(s).charAt(0).toUpperCase() + String(s).slice(1), words: (s) => String(s).trim().split(/\s+/), pad_left: (s, n, c = " ") => String(s).padStart(n, c), pad_right: (s, n, c = " ") => String(s).padEnd(n, c) },
  collections: { flatten: (xs) => xs.flat(Infinity), unique: (xs) => [...new Set(xs)], chunk: (xs, n) => Array.from({ length: Math.ceil(xs.length / n) }, (_, i) => xs.slice(i * n, i * n + n)) },
  map: { merge: (...xs) => Object.assign({}, ...xs), pick: (m, ks) => Object.fromEntries(ks.filter((k) => k in m).map((k) => [k, m[k]])), omit: (m, ks) => Object.fromEntries(Object.entries(m).filter(([k]) => !ks.includes(k))) },
  json: { to_json: JSON.stringify, from_json: JSON.parse, pretty: (x) => JSON.stringify(x, null, 2) },
};
function loadModule(name) {
  if (!modules[name]) throw new Error(`unknown module: ${name}`);
  return modules[name];
}
function resolveModule(name) {
  return loadModule(name);
}
module.exports = { modules, loadModule, resolveModule };
