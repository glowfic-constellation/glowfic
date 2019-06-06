module.exports = function (casper, ready) {
  casper.thenOpen(casper.getCurrentUrl() + "?view=flat&pp=skip"); // redirect to original page
  casper.wait(50, ready);
}
