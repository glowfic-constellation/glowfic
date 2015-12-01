image_ids = []
$(document).ready( function() {
  $(".add-gallery-icon").click(function() {
    $(this).toggleClass('default-icon');
    if ($(this).hasClass('default-icon')) {
      image_ids.push(this.dataset['id']);
    } else {
      image_ids.pop(this.dataset['id']);
    }
  });

  $("#add-gallery-icons").submit(function() {
    if (image_ids.length < 1) { return false; }
    $("#image_ids").val(image_ids);
    return true;
  });
}); 
