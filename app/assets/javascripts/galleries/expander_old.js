$(document).ready(function() {
  $('.gallery-minmax').click(function(event) {
    var elem = $('a', this);
    var id = $(this).data('id');
    if (elem.html().trim() === '-') {
      $('.gallery-data-' + id).hide();
      elem.html('+');
    } else {
      $('.gallery-data-' + id).show();
      elem.html('-');
    }
    event.preventDefault();
  });
});
