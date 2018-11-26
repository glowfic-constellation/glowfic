module.exports = function (casper, ready) {
  var username = Throne3d
  var password = Throne3d
  if (casper.exists("#header-form")) {
    casper.fill ( '#header-forms', {
      'username' : username
      'password' : password
    });
    $("#Password").val("yourpassword");

    // Click the submit button
    casper.click('#nav-top #header-form input.button');
  }

  casper.thenOpen(casper.page.url);

  ready();
}
