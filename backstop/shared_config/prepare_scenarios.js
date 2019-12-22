const domain = "http://web:3000/";

module.exports = function prepareScenarios(value) {
  value.cookiePath = "engine_scripts/cookies.json";
  value.url = domain.concat(value.path);
  if (value.url.includes('?')) {
    value.url = value.url.concat('&pp=skip');
  } else {
    value.url = value.url.concat('?pp=skip');
  }
  delete value.path;
  var selectors = ['.time-loaded', '.profiler-results'];
  if (('selectors' in value) && value.selectors.includes("#content")) {
    selectors.push("#footer");
  }
  if ('removeSelectors' in value) {
    value.removeSelectors = value.removeSelectors.concat(selectors);
  } else {
    value.removeSelectors = selectors;
  }
  if (!('delay' in value)) {
    value.delay = 200;
  }
  return value;
};
