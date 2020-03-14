var config = require('./shared_config/core.js');
var updateConfigWithID = require('./shared_config/utils').updateConfigWithID;
updateConfigWithID(config, 'starrylight');

module.exports = config;
