$(document).ready(function() {
  $("#user_per_page").select2({
    width: '70px',
    minimumResultsForSearch: 20,
  });

  $("#user_default_view").select2({
    width: '100px',
    minimumResultsForSearch: 20,
  });

  $("#user_default_editor").select2({
    width: '100px',
    minimumResultsForSearch: 20,
  });

  $("#user_layout").select2({
    width: '150px',
    minimumResultsForSearch: 20,
  });

  $("#user_timezone").select2({width: '250px'});

  $("#user_time_display").select2({
    width: '200px',
    minimumResultsForSearch: 20
  });
});
