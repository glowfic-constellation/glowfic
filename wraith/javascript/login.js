module.exports = function (casper, ready) {
  if (casper.exists("#header-form")) {
    casper.fill ( '#header-forms', {
      'username': 'Throne3d',
      'password': 'throne3d'
    });

    casper.click('#nav-top #header-form input.button');

    casper.wait(5000);

    casper.thenOpen(casper.page.url);
  }

  ready();
}
