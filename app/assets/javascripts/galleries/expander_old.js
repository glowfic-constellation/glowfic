$(document).ready(function() {
  $('.gallery-minmax').click(function() {
    var elem = $(this);
    var id = elem.data('id');
    if (elem.html().trim() === '-') {
      $('#gallery' + id).hide();
      elem.html('+');
    } else {
      $('#gallery' + id).show();
      elem.html('-');
    }
  });
});
