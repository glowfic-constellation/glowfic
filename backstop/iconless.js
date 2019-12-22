var config = require('./shared_config/core.js');
const prepareScenarios = require('./shared_config/prepare_scenarios.js');

const scenarios = [
  {
    label: "characters_icon_split",
    path: "users/3/characters?character_split=template&view=icons",
    selectors: ["#content"]
  },
  {
    label: "gallery_show",
    path: "galleries/26",
    selectors: ["#content"]
  },
  {
    label: "post_show",
    path: "posts/3",
    selectors: ["#content"],
    delay: 5000
  },
  {
    label: "icon_selector",
    path: "posts/new",
    selectors: ["#reply-icon-selector"],
    clickSelector: '#current-icon-holder'
  },
];

config.id = 'iconless';
config.scenarios = scenarios.map(prepareScenarios);
config.paths.bitmaps_reference = "then/iconless";
config.paths.bitmaps_test = "now/iconless";
config.paths.html_report = "reports/iconless";
config.paths.ci_report = "reports/iconless";

module.exports = config;
