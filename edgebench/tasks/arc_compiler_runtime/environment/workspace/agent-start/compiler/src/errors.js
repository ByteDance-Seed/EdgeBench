class ArcError extends Error {
  constructor(message, loc) {
    super(message);
    this.name = "ArcError";
    this.loc = loc;
  }
}
function formatError(error) {
  return error?.stack || error?.message || String(error);
}
module.exports = { ArcError, formatError };
