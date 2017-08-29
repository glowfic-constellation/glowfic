// orderBox is the box the ordering is scoped to
// so that a single page can have multiple separate ordering structures
function bindArrows(orderBox, path, param) {
  $(".section-up", orderBox).click(function() {
    var sourceRow = $(this).closest('.section-ordered');
    var targetRow = sourceRow.prev('.section-ordered');
    if (targetRow.length === 0) return false;
    moveRow(sourceRow, targetRow, orderBox, path, param);
    return false;
  }).addClass('pointer').removeClass('disabled-arrow');

  $(".section-down", orderBox).click(function() {
    var sourceRow = $(this).closest('.section-ordered');
    var targetRow = sourceRow.next('.section-ordered');
    if (targetRow.length === 0) return false;
    moveRow(sourceRow, targetRow, orderBox, path, param);
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
  var rows = $('.section-ordered', arrowBox);
  var ordered = rows.sort(function(a, b) { return $(a).data('order') > $(b).data('order') ? 1 : -1; }).appendTo(arrowBox);
  $("tr:even:not(.section-warning) td", orderBox).removeClass('even').addClass('odd');
  $("tr:odd:not(.section-warning) td", orderBox).removeClass('odd').addClass('even');
  return ordered;
}

function moveRow(sourceRow, targetRow, orderBox, path, param) {
  // Reduce race conditions by only allowing one update at a time
  unbindArrows(orderBox);
  $("#loading", orderBox).show();
  $("#saveconf", orderBox).stop(true, true).hide();

  // Switch the row order pre-emptively
  var sourceOrder = sourceRow.data('order');
  var targetOrder = targetRow.data('order');
  sourceRow.data('order', targetOrder);
  targetRow.data('order', sourceOrder);
  var orderedRows = reorderRows(orderBox);

  // Figure out the full desired order and send it to the server
  var orderedIds = [];
  orderedRows.each(function() {
    orderedIds.push(parseInt($(this).data('id')));
  });
  var json = {};
  json['ordered_' + param] = orderedIds;
  // and restrict to relevant section_id if given
  if (window.gon && window.gon.section_id) json.section_id = window.gon.section_id;

  $.post(path, json, function(resp) {
    // Check the list doesn't have new elements
    if (orderedRows.length !== resp[param].length && $('.section-warning', orderBox).length === 0) {
      var warning = $("<tr class='section-warning'>").append($("<td>").html('There are items missing from this list! Please reload.'));
      orderBox.prepend(warning);
      console.log(resp.responseText);
    }

    // Set the full ordering according to the server response
    var returnedIds = resp[param];
    orderedRows.each(function() {
      var row = $(this);
      row.data('order', returnedIds.indexOf(row.data('id')));
    });
    reorderRows(orderBox);

    // Re-enable the buttons
    $("#loading", orderBox).hide();
    $("#saveconf", orderBox).show().delay(2000).fadeOut();
    bindArrows(orderBox, path, param);
  }).fail(function(resp) {
    // Display an error and debug to console
    $("#loading", orderBox).hide();
    $("#saveerror", orderBox).show();
    if ($('.section-warning', orderBox).length === 0) {
      var specificMessage = '';
      if (resp.status === 404) {
        specificMessage = 'One or more of the items could not be found. ';
      }
      var warning = $("<tr class='section-warning'>").append($("<td>").html('There was an error saving your changes! ' + specificMessage + 'Please reload. <em>(' + resp.status + ')</em>'));
      orderBox.prepend(warning);
      console.log(resp.responseText);
    }
  });
}
