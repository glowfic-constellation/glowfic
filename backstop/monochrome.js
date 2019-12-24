var config = require('./shared_config/scenarios_shortlist.js');
var updateConfigWithID = require('./shared_config/utils').updateConfigWithID;
updateConfigWithID(config, 'monochrome');

module.exports = config;
