$(document).ready(function() {
  $(".expanddesc").click(function() {
    const id = $(this).attr('id').substring(11);
    if ($(this).text()[0] === "m") {
      $("#desc-"+id).show();
      $("#dots-"+id).hide();
      $(this).html(' &laquo; less');
    } else {
      $("#desc-"+id).hide();
      $("#dots-"+id).show();
      $(this).html('more &raquo;');
    }
    return false;
  });
});
