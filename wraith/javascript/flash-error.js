module.exports = function (casper, ready) {
  casper.thenOpen(casper.page.url + '/-1');

  ready();
}
