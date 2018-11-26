module.exports = function (casper, ready) {
  casper.options.logLevel = 'debug';
  
  casper.evaluate(function() {
    $("#header").hide();
    $(".flash").hide();
    $("#footer").hide();
  });
}
