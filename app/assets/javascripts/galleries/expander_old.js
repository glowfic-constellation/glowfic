$(document).ready(function() {
  $('.gallery-minmax').click(function() {
    var elem = $(this);
    var id = elem.data('id');
    if (elem.html().trim() === '-') {
      $('.gallery-data-' + id).hide();
      elem.html('+');
    } else {
      $('.gallery-data-' + id).show();
      elem.html('-');
    }
  });
});
