var config = require('./core.js');
var prepareScenarios = require('./prepare_scenarios.js');

const filteredScenarios = require('./scenarios_filtered.js');

const scenarios = filteredScenarios([
  "home",
  "characters_icon_split",
  "characters_list_combined",
  "galleries",
  "gallery_show",
  "post_edit",
  "posts_unread",
  "post_show_html",
  "report_daily",
]);

config.scenarios = scenarios.map(prepareScenarios);

module.exports = config;
