const loadCookies = require('./loadCookies');
module.exports = async (page, scenario, _vp) => {
  await loadCookies(page, scenario);

  // skip spam messages in console
  const oldLog = console.log;
  console.log = (...args) => {
    if (args.length === 1 && args[0].includes("BackstopTools have been installed")) return;
    oldLog(...args);
  };
};
