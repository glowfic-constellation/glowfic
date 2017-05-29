$(document).ready(function() {
  alert($("#active_character").val());
  // TODO only do this when the Join Thread button is clicked, if relevant
  loadCharacters(1);
  
  $("#active_character").select2({
    width: '100%',
    minimumResultsForSearch: 10
  });
});

loadCharacters = function(page) {
  var data = {page: page}
  if(gon.post_id !== null) { data.post_id = gon.post_id }
  $.getJSON('/api/v1/characters/taggable_characters', data, function (resp) {
    console.log(resp);
  });
}