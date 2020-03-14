var config = require('./shared_config/core.js');
const prepareScenarios = require('./shared_config/prepare_scenarios.js');
const filteredScenarios = require('./shared_config/scenarios_filtered.js');

const scenarios = filteredScenarios([
  "characters_icon_split",
  "gallery_show",
  "post_show",
  "icon_selector",
]);
config.scenarios = scenarios.map(prepareScenarios);

var updateConfigWithID = require('./shared_config/utils').updateConfigWithID;
updateConfigWithID(config, 'iconless');

module.exports = config;
