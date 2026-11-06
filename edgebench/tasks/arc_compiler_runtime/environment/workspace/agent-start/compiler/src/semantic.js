function analyze(program) {
  return { ok: true, errors: [], warnings: [], program };
}
function checkSemantics(program) {
  return analyze(program);
}
module.exports = { analyze, checkSemantics };
