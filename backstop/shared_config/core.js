const scenarios = require('./scenarios_full.js');
const prepareScenarios = require('./prepare_scenarios.js');

module.exports = {
  viewports: [
    {
      label: "phone",
      width: 320,
      height: 480
    },
    {
      label: "tablet",
      width: 1024,
      height: 768
    },
  ],
  onBeforeScript: "puppet/onBefore.js",
  onReadyScript: "puppet/onReady.js",
  scenarios: scenarios.map(prepareScenarios),
  paths: {
    engine_scripts: "engine_scripts",
  },
  report: ["browser"],
  engine: "puppeteer",
  engineOptions: {
    args: ["--no-sandbox"]
  },
  asyncCaptureLimit: 5,
  asyncCompareLimit: 50,
  debug: false,
  debugWindow: false
};
