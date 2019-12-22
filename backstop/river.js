var config = require('./shared_config/scenarios_shortlist.js');

config.id = 'river';
config.paths.bitmaps_reference = "then/river";
config.paths.bitmaps_test = "now/river";
config.paths.html_report = "reports/river";
config.paths.ci_report = "reports/river";

module.exports = config;
