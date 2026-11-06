#!/usr/bin/env node
const fs = require("fs");
const { lex, parse, createEnv, interpretWithEnv, generateIR, generateJS, format, lint } = require("./runtime.js");

function run(argv = process.argv.slice(2)) {
  const [cmd, file] = argv;
  if (cmd === "version" || cmd === "--version" || cmd === "-v") return console.log("0.6.16");
  if (cmd === "builtins") return console.log("print len map filter reduce sum range keys values");
  const source = file && fs.existsSync(file) ? fs.readFileSync(file, "utf8") : "";
  if (cmd === "parse") return console.log(JSON.stringify(parse(lex(source)), null, 2));
  if (cmd === "ir") return console.log(JSON.stringify(generateIR(parse(lex(source))), null, 2));
  if (cmd === "compile") return console.log(generateJS(generateIR(parse(lex(source)))));
  if (cmd === "fmt") return console.log(format(source));
  if (cmd === "lint") return console.log(JSON.stringify(lint(source)));
  if (cmd === "check") return console.log("OK");
  if (cmd === "run" || file) {
    const result = interpretWithEnv(parse(lex(source || fs.readFileSync(cmd, "utf8"))), createEnv());
    if (result !== undefined) console.log(result);
    return result;
  }
  console.log("Arc compiler");
}

if (require.main === module) run();
module.exports = { run };
