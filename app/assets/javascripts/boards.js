$(document).ready(function() {
  $("#board_coauthor_id").chosen({ 
    width: '246px;' ,
    disable_search_threshold: 10,
  });

  $("#sortable").sortable({
    placeholder: "placeholder",
    stop: function(event, ui) {
      var idsInOrder = $("#sortable").sortable("toArray");
      var idPos = {};
      for(var i = 0; i < idsInOrder.length; i++) {
        var postId = idsInOrder[i].substring(5);
        idPos[postId] = i;
      }
      // TODO ajax call to save this ordering
      $("#saveconf").fadeIn().delay(3000).fadeOut();
    }
  });
});
