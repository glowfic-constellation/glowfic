var config = require('./shared_config/scenarios_shortlist.js');

config.id = 'monochrome';
config.paths.bitmaps_reference = "then/monochrome";
config.paths.bitmaps_test = "now/monochrome";
config.paths.html_report = "reports/monochrome";
config.paths.ci_report = "reports/monochrome";

module.exports = config;
