$(document).ready(function() {
  $("#board_coauthor_ids").select2({ 
    width: '100%' ,
    minimumResultsForSearch: 10,
    placeholder: 'Open to Anyone'
  });
  $("#board_cameo_ids").select2({ 
    width: '100%' ,
    minimumResultsForSearch: 10,
    placeholder: '(Optional)'
  });

  // Dropdown menu code
  if ($("#post-menu").length > 0) {
    $("#post-menu").click(function() {
      $(this).toggleClass('selected');
      $("#post-menu-box").toggle();
    });

    // Hides selectors when you hit the escape key
    $(document).bind("keydown", function(e){
      e = e || window.event;
      var charCode = e.which || e.keyCode;
      if(charCode === 27) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });

    // Hides selectors when you click outside them
    $(document).click(function(e) {
      var target = e.target;

      if (!$(target).is('#post-menu-box') && !$(target).parents().is('#post-menu-box')
        && !$(target).is('#post-menu') && !$(target).parents().is('#post-menu')) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });
  }
});
