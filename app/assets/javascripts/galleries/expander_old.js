$(document).ready(function() {
  $('.gallery-minmax').click(function(event) {
    const elem = $('a', this);
    const id = $(this).data('id');
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
