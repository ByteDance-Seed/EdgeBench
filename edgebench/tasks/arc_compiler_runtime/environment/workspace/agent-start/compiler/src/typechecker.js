function checkTypes(program) {
  return { ok: true, errors: [], types: new Map(), program };
}
function typeCheck(program) {
  return checkTypes(program);
}
module.exports = { checkTypes, typeCheck };
