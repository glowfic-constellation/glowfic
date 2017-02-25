$(document).ready(function() {
  $("#message_recipient_id").select2({
    width: '230px',
    minimumResultsForSearch: 20,
  });

  $(".message-collapse").click(function() {
    $(this).hide();
    $("#expanded-"+$(this).data('id')).show();
  });

  $(".message-expand").click(function() {
    $(this).hide();
    $("#collapsed-"+$(this).data('id')).show();
  });
});
