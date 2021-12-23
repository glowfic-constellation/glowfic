/* global gon */
$(document).ready(function() {
  // Bind both change() and keyup() in the icon keyword dropdown because Firefox doesn't
  // respect up/down key selections in a dropdown as a valid change() trigger
  $("#icon_dropdown").change(function() { setIconFromId($(this).val()); });
  $("#icon_dropdown").keyup(function() { setIconFromId($(this).val()); });
});

function setIconFromId(id) {
  $("#new_icon").attr('src', gon.gallery[id].url);
  $("#new_icon").attr('alt', gon.gallery[id].keyword);
  $("#new_icon").attr('title', gon.gallery[id].keyword);
  if (typeof gon.gallery[id].aliases !== "undefined") {
    const aliases = gon.gallery[id].aliases;
    if (aliases.length > 0) {
      $("#alias_dropdown").show().empty().append('<option value="">— No alias —</option>');
      for (let i = 0; i < aliases.length; i++) {
        $("#alias_dropdown").append($("<option>").attr({value: aliases[i].id}).text(aliases[i].name));
      }
    } else {
      $("#alias_dropdown").hide().val('');
    }
  }
}
