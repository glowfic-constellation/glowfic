$(document).ready( function() {
  $(".section-up").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order - 1;
    if (old_order === 0) { return false; }
    switchRows(old_order, new_order);
    return false;
  });

  $(".section-down").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order + 1;
    if (document.getElementById("section-"+new_order) === null) { return false; }
    switchRows(old_order, new_order);
    return false;
  });
});

function switchRows(old_order, new_order) {
  var this_row = $("#section-"+old_order);
  var this_gal = $("#section-gallery-"+old_order);
  var that_row = $("#section-"+new_order);
  var that_gal = $("#section-gallery-"+new_order);

  $("#section-"+old_order+" img").attr('data-order', new_order);
  $("#section-"+new_order+" img").attr('data-order', old_order);
  this_row.attr('id', "section-"+new_order);
  that_row.attr('id', "section-"+old_order);
  this_gal.attr('id', "section-gallery-"+new_order);
  that_gal.attr('id', "section-gallery-"+old_order);

  if(old_order > new_order) {
    this_row.insertBefore(that_row);
    this_gal.insertBefore(that_row);
  } else {
    this_gal.insertAfter(that_gal);
    this_row.insertAfter(that_gal);
  }

  var json = {changes: {}, commit: 'reorder'};
  json['changes'][this_row.attr('data-section')] = new_order;
  json['changes'][that_row.attr('data-section')] = old_order;
  $.post('/characters', json, function (resp) {});
}
