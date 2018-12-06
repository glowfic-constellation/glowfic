module.exports = function (casper, ready) {
  casper.options.verbose = true;

  casper.evaluate(function() {
    if($("#tos").length > 0) {
      $("#tos").hide();
      $("#content").show();
    }
  });

  casper.then(function() {
    if (casper.exists(".time-loaded")) {
      casper.evaluate(function() {
        $(".time-loaded").hide();
      });
    }
    if (casper.cli.get(3) == "[id=content]") {
      casper.evaluate(function() {
        $("#footer").hide();
      });
    }

    casper.wait(100);
    casper.evaluate(function() {
      $(".profiler-result").hide();
    });
  });

  casper.wait(1000, ready);
}
