// Runs before each test file. The app's Sprockets JS files are not modules:
// many call `$(document).ready(...)` at load time, which would throw under
// jsdom because jQuery isn't present. Provide a minimal stub so those files
// can be required for unit testing. Individual tests can override `$` as needed.
global.$ = global.jQuery = function() {
  return { ready: function() {} };
};
