module.exports = function (casper, ready) {
  casper.options.verbose = true;
  casper.options.logLevel = "debug"

  if (casper.exists("#header-form")) {
    casper.fill ( '#header-forms', {
      'username': 'Throne3d',
      'password': 'throne3d'
    });

    casper.click('#nav-top #header-form input.button');

    casper.wait(100);

    if (casper.getCurrentUrl() != casper.cli.get(0)) {
      casper.thenOpen(casper.cli.get(0)); // redirect to original page
    }
  }

  ready();
}
