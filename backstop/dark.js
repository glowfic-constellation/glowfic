var config = require('./shared_config/scenarios_shortlist.js');

config.id = 'dark';
config.paths.bitmaps_reference = "then/dark";
config.paths.bitmaps_test = "now/dark";
config.paths.html_report = "reports/dark";
config.paths.ci_report = "reports/dark";

module.exports = config;
