$(document).ready(function() {
  $("#content table").each(function() {
    var maxheight = 0;
    $(this).find('.gallery-icon').each(function() {
      if($(this).height() > maxheight) { maxheight = $(this).height(); }
    });
    $(this).find('.gallery-icon').css('height', maxheight+'px');
  });
});