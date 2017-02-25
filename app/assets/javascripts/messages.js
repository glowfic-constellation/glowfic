$(document).ready(function() {
  $("#message_recipient_id").select2({
    width: '230px',
    minimumResultsForSearch: 20
  });

  $(".message-collapse").click(function() { swapView(this, 'collapsed', 'expanded'); });
  $(".message-menu").click(function() { swapView(this, 'expanded', 'collapsed'); });
});

function swapView(cur, hide, other) {
  var id = $(cur).data('id');
  $("#" + hide + "-" + id).hide();
  $("#" + other + "-" + id).show();
}
