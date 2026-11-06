const { lex, parse, createEnv, interpretWithEnv } = require("./runtime.js");
function evaluate(source, env = createEnv()) {
  return interpretWithEnv(parse(lex(source)), env);
}
module.exports = { evaluate };
