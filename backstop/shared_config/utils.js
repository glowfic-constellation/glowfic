function updateConfigWithID(config, id) {
  config.id = id;
  config.paths.bitmaps_reference = `then/${id}`;
  config.paths.bitmaps_test = `now/${id}`;
  config.paths.html_report = `reports/${id}`;
  config.paths.ci_report = `reports/${id}`;
}

module.exports = {
  updateConfigWithID,
};
