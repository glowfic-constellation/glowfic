image_ids = []
skip_warning = false;
$(document).ready( function() {
  $(".add-gallery-icon").click(function() {
    $(this).toggleClass('selected-icon');
    if ($(this).hasClass('selected-icon')) {
      image_ids.push(this.dataset['id']);
    } else {
      image_ids.pop(this.dataset['id']);
    }
  });

  $("#add-gallery-icons").submit(function() {
    if (image_ids.length < 1) { return false; }
    $("#image_ids").val(image_ids);
    skip_warning = true;
    return true;
  });
});

$(window).on('beforeunload', function(){
  if (skip_warning || image_ids.length == 0) return;
  return "Are you sure you wish to navigate away? You have " + image_ids.length + " image(s) selected.";
});
