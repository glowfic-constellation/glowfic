$(document).ready(function() {
  $("#user_per_page").chosen({
    width: '70px',
    disable_search_threshold: 20,
  });

  $("#user_default_view").chosen({
    width: '100px',
    disable_search_threshold: 20,
  });

  $("#user_default_editor").chosen({
    width: '100px',
    disable_search_threshold: 20,
  });

  $("#user_layout").chosen({
    width: '150px',
    disable_search_threshold: 20,
  });

  $("#user_timezone").chosen({width: '250px'});
  
  $("#user_time_display").chosen({
    width: '200px',
    disable_search_threshold: 20
  });
});
