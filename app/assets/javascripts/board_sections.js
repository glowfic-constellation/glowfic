$(document).ready(function() {
  bindArrows($("#reorder-posts-table"));
});

// orderBox is the box the ordering is scoped to
// so that a single page can have multiple separate ordering structures
function bindArrows(orderBox) {
  $(".section-up", orderBox).click(function() {
    var sourceRow = $(this).closest('.section-ordered');
    var targetRow = sourceRow.prev('.section-ordered');
    if (targetRow.length === 0) return false;
    moveRow(sourceRow, targetRow, orderBox);
    return false;
  }).addClass('pointer').removeClass('disabled-arrow');

  $(".section-down", orderBox).click(function() {
    var sourceRow = $(this).closest('.section-ordered');
    var targetRow = sourceRow.next('.section-ordered');
    if (targetRow.length === 0) return false;
    moveRow(sourceRow, targetRow, orderBox);
    return false;
  }).addClass('pointer').removeClass('disabled-arrow');

  $(".section-up", orderBox).first().addClass('disabled-arrow').removeClass('pointer');
  $(".section-down", orderBox).last().addClass('disabled-arrow').removeClass('pointer');
}

function unbindArrows(orderBox) {
  $(".section-down", orderBox).unbind().addClass('disabled-arrow').removeClass('pointer');
  $(".section-up", orderBox).unbind().addClass('disabled-arrow').removeClass('pointer');
}

function reorderRows(orderBox) {
  var arrowBox = $('tbody', orderBox);
  var rows = $('.section-ordered', orderBox);
  rows.sort(function(a, b) { return $(a).data('order') > $(b).data('order') ? 1 : -1; }).appendTo(arrowBox);
  $("tr:even td", orderBox).removeClass('even').addClass('odd');
  $("tr:odd td", orderBox).removeClass('odd').addClass('even');
}

function moveRow(sourceRow, targetRow, orderBox) {
  unbindArrows(orderBox);
  // Reduce race conditions by only allowing one update at a time
  $("#loading", orderBox).show();
  $("#saveconf", orderBox).stop(true, true).hide();

  var sourceOrder = sourceRow.data('order');
  var targetOrder = targetRow.data('order');
  sourceRow.data('order', targetOrder);
  targetRow.data('order', sourceOrder);

  reorderRows(orderBox);

  var json = {changes: {}};
  sourceRow.add(targetRow).each(function() {
    var row = $(this);
    json.changes[row.data('id')] = {
      type: row.data('type'),
      order: row.data('order')
    };
  });
  $.post('/api/v1/board_sections/reorder', json, function() {
    $("#loading", orderBox).hide();
    $("#saveconf", orderBox).show().delay(2000).fadeOut();
    bindArrows(orderBox);
  });
}
