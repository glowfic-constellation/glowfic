$(document).ready(function() {
  $("#board_coauthor_ids").select2({ 
    width: '100%' ,
    minimumResultsForSearch: 10,
    placeholder: 'Open to Anyone',
  });
  $("#board_cameo_ids").select2({ 
    width: '100%' ,
    minimumResultsForSearch: 10,
    placeholder: '(Optional)',
  });
});
