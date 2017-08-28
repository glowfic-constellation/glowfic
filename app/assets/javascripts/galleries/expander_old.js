$(document).ready(function() {
  $('.gallery-minmax').click(function() {
    var elem = $(this);
    var id = elem.data('id');
    if (elem.html().trim() === '-') {
      $('#gallery' + id).hide();
      $('#gallery-tags-' + id).hide();
      elem.html('+');
    } else {
      $('#gallery' + id).show();
      $('#gallery-tags-' + id).show();
      elem.html('-');
    }
  });
});
