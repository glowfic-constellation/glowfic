$(document).ready(function() {
  bindArrows();
});

function bindArrows() {
  $(".section-up").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order - 1;
    if (old_order === 0) return false;
    switchRows(old_order, new_order);
    return false;
  });

  $(".section-down").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order + 1;
    if (document.getElementById("section-"+new_order) === null) return false;
    switchRows(old_order, new_order);
    return false;
  });
}

function unbindArrows() {
  $(".section-down").unbind();
  $(".section-up").unbind();
}

function switchRows(old_order, new_order) {
  unbindArrows(); // Reduce race conditions by only allowing one update at a time
  $("#loading").show();
  $("#saveconf").stop(true, true).hide();

  var this_row = $("#section-"+old_order);
  var that_row = $("#section-"+new_order);
  $("#section-"+old_order+" img").attr('data-order', new_order);
  $("#section-"+new_order+" img").attr('data-order', old_order);
  this_row.attr('id', "section-"+new_order);
  that_row.attr('id', "section-"+old_order);

  if (old_order > new_order) {
    this_row.insertBefore(that_row);
  } else {
    this_row.insertAfter(that_row);
  }
  $("#section-table tr:odd td").removeClass('even').addClass("odd");
  $("#section-table tr:even td").removeClass('odd').addClass("even");

  var json = {changes: {}};
  json.changes[this_row.attr('data-section')] = {
    type: this_row.attr('data-type'),
    order: new_order
  };
  json.changes[that_row.attr('data-section')] = {
    type: that_row.attr('data-type'),
    order: old_order
  };
  $.post('/api/v1/board_sections/reorder', json, function() {
    $("#loading").hide();
    $("#saveconf").show().delay(2000).fadeOut();
    bindArrows();
  });
}
