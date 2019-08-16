module.exports = function(casper, ready) {
  casper.evaluate(function() {
    $('#character-selector').toggle();
  });
  casper.then(function() {
    casper.click('#select2-active_character-container');
  });
  ready();
};
