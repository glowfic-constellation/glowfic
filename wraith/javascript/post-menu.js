module.exports = function (casper, ready) {
  casper.options.verbose = true;
  casper.options.logLevel = "debug"

  casper.wait(2000, function() {
    casper.click('#post-menu');
    ready();
  });
}
