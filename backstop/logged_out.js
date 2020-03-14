var config = require('./shared_config/core.js');
const prepareScenarios = require('./shared_config/prepare_scenarios.js');
const filteredScenarios = require('./shared_config/scenarios_filtered.js');

const scenarios = filteredScenarios([
  'home',
  'signup',
  'login',
  'password_reset',
]);

var updateConfigWithID = require('./shared_config/utils').updateConfigWithID;
updateConfigWithID(config, 'logged_out');

config.scenarios = scenarios.map(prepareScenarios);
config.scenarios = config.scenarios.map(function(value) {
  return Object.assign({}, value, {cookiePath: 'engine_scripts/tos.json'});
});

module.exports = config;
