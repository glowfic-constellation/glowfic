module.exports = function(casper, ready) {
  casper.evaluate(function() {
    $("#swap-character").click(function() {
      $('#character-selector').toggle();
      $('#alias-selector').hide();
      $('html, body').scrollTop($("#post-editor").offset().top);
    });
  });
  ready();
};
