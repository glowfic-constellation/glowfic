/* global createSelect2 */

$(document).ready(function() {
  createSelect2('#message_recipient_id', {
    width: '230px',
    minimumResultsForSearch: 20
  });

  $(".message-collapse").click(function() { swapView(this, 'collapsed', 'expanded'); });
  $(".message-menu").click(function() { swapView(this, 'expanded', 'collapsed'); });
});

function swapView(cur, hide, other) {
  const id = $(cur).data('id');
  $("#" + hide + "-" + id).hide();
  $("#" + other + "-" + id).show();
}
