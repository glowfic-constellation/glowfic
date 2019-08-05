module.exports = function(casper, ready) {
  $("#swap-character").click(function() {
    $('#character-selector').toggle();
    $('#alias-selector').hide();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });
};
