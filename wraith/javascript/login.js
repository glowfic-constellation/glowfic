module.exports = function (casper, ready) {
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

  casper.then(function() {
    if (casper.exists(".time-loaded")) {
      casper.evaluate(function() {
        $(".time-loaded").hide();
      });
    }
    casper.evaluate(function() {
      $(".profiler-result").hide();
    });
    if (casper.cli.get(3) == "[id=content]") {
      casper.evaluate(function() {
        $("#footer").hide();
      });
    }
  });

  ready();
}
