module.exports = function (casper, ready) {
  casper.evaluate(function() {
    $("#header").hide();
    $(".flash").hide();
    $("#footer").hide();
  });

  ready();
}
