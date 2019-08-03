module.exports = function(casper, ready) {
  casper.wait(2000, function() {
    casper.click('#current-icon-holder');
    ready();
  });
};
