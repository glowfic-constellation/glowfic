$(document).ready(function () {
  $(".gallery-box").click(function() {
    var id = $(this).attr('id');
    $('#gallery'+id).toggle();
    $(this).html($(this).html() == '-' ? '+' : '-');
  });
});
