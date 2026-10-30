const { generateJS } = require("./runtime.js");
function generateWAT(ir) {
  return `(module (func (export "main") (result i32) i32.const 0))`;
}
module.exports = { generateWAT, generateJS };
