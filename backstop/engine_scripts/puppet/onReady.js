const clickAndHoverHelper = require('./clickAndHoverHelper');
module.exports = async (page, scenario, _vp) => {
  console.log('SCENARIO > ' + scenario.label);
  await clickAndHoverHelper(page, scenario);
};
