module.exports = function (casper, ready) {
  casper.options.verbose = true;

  casper.evaluate(function() {
    if($("#tos").length > 0) {
      $("#tos").hide();
      $("#content").show();
    }
  });

  casper.wait(10000, ready);
}
