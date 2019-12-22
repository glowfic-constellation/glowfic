var config = require('./shared_config/core.js');
const prepareScenarios = require('./shared_config/prepare_scenarios.js');

const scenarios = [
  {
    label: "home",
    path: "",
  },
  {
    label: "signup",
    path: "users/new",
    selectors: ["#content"]
  },
  {
    label: "login",
    path: "login",
    selectors: ["#content"]
  },
  {
    label: "password_reset",
    path: "password_resets/new",
    selectors: ["#content"],
  },
];

config.id = 'logged_out';
config.scenarios = scenarios.map(prepareScenarios);
config.scenarios = config.scenarios.map(function(value) {
  value.cookiePath = 'engine_scripts/tos.json';
  return value;
});
config.paths.bitmaps_reference = "then/logged_out";
config.paths.bitmaps_test = "now/logged_out";
config.paths.html_report = "reports/logged_out";
config.paths.ci_report = "reports/logged_out";

module.exports = config;
