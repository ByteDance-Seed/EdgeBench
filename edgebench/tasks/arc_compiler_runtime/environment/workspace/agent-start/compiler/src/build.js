function buildProject() {
  return { ok: true, outputs: [] };
}
function scaffoldProject(name) {
  return { name, files: [] };
}
module.exports = { buildProject, scaffoldProject };
