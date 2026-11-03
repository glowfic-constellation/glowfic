const fs = require('fs');
const path = require('path');

// The app's JS is served by Sprockets as plain concatenated <script>s, not
// modules: top-level `function foo() {}` declarations become browser globals.
// `loadGlobals` mirrors that — it evaluates a source file in the jsdom global
// scope (via indirect eval) and hands back the requested globals — so app code
// can be unit-tested without bolting a CommonJS `module.exports` onto it.
function loadGlobals(relativePath, names) {
  const fullPath = path.resolve(__dirname, '../../..', relativePath);
  const src = fs.readFileSync(fullPath, 'utf8');
  (0, eval)(src); // indirect eval always runs in global scope, like a <script> tag
  const picked = {};
  names.forEach(function(name) { picked[name] = globalThis[name]; });
  return picked;
}

module.exports = { loadGlobals };
