$(document).ready(function() {
  // When the "Check All" checkbox is toggled
  $('#check-all').on('change', function() {
    $('.checkbox').prop('checked', this.checked);
  });

  // When any child checkbox is toggled
  $('.checkbox').on('change', function() {
    if ($('.checkbox:checked').length !== $('.checkbox').length) {
      $('#check-all').prop('checked', false);
    } else {
      $('#check-all').prop('checked', true);
    }
  });
});
