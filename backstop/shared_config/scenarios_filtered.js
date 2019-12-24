const fullScenarios = require('./scenarios_full');

// setDiff treats haystack and needles as sets, and finds
// the elements of haystack that are not in needles.
const setDiff = function(haystack, needles) {
  const set1 = new Set(haystack);
  const set2 = new Set(needles);
  return [...set1].filter(x => !set2.has(x));
};

const filteredScenarios = function(labelList) {
  const scenarios = [];
  fullScenarios.forEach(scenario => {
    if (!labelList.includes(scenario.label)) return;
    scenarios.push(scenario);
  });

  // confirm all scenarios were found
  const foundLabels = scenarios.map(x => x.label);
  const missingLabels = setDiff(labelList, foundLabels);
  if (missingLabels.length !== 0) {
    throw new Error("failed to find all labels! missing: " + missingLabels.join(', '));
  }

  return scenarios;
};

module.exports = filteredScenarios;
