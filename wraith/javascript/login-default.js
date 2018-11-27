module.exports = function (casper, ready) {
  url = casper.getCurrentUrl()
  if (casper.exists("#header-form")) {
    casper.fill ( '#header-forms', {
      'username' : "Throne3d"
      'password' : "throne3d"
    });

    casper.click('#nav-top #header-form input.button');
  }

  casper.thenOpen(url);

  ready();
}
