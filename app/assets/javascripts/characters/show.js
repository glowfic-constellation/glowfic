//= require galleries/expander_old
//= require reorder
/* global swapRows */
/* exported reorderRows */

$(document).ready(function() {
  bindArrows($("#reorder-galleries-table"), '/api/v1/characters/reorder', 'characters_gallery_ids');
});

// override standard reorder
function bindArrows(orderBox, path, param) {
  $(".section-up", orderBox).click(function() {
    const sourceRow = $(this).closest('.section-ordered');
    const targetRow = sourceRow.prevUntil('.section-ordered').last().prev();
    if (targetRow.length === 0) return false;
    swapRows(sourceRow, targetRow, orderBox, path, param);
    return false;
  }).addClass('pointer').removeClass('disabled-arrow');

  $(".section-down", orderBox).click(function() {
    const sourceRow = $(this).closest('.section-ordered');
    const targetRow = sourceRow.nextUntil('.section-ordered').last().next();
    if (targetRow.length === 0) return false;
    swapRows(sourceRow, targetRow, orderBox, path, param);
    return false;
  }).addClass('pointer').removeClass('disabled-arrow');

  $(".section-up", orderBox).first().addClass('disabled-arrow').removeClass('pointer');
  $(".section-down", orderBox).last().addClass('disabled-arrow').removeClass('pointer');
}

// override standard reorder
function reorderRows(orderBox) {
  const rows = $('.section-ordered', orderBox);
  const ordered = rows.sort(function(a, b) { return $(a).data('order') > $(b).data('order') ? 1 : -1; }).each(function() {
    const attaches = $(this).nextUntil('.section-ordered');
    orderBox.append(this, attaches.get());
  });
  return ordered;
}
