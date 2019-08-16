module.exports = function(casper, ready) {
  casper.click('input.button')
  ready();
};
