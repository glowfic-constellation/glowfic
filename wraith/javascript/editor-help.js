module.exports = function(casper, ready) {
  casper.evaluate(function() {
    $("#editor-help-box").dialog('open');
  });
  ready();
};
