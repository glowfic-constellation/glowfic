$(document).ready(function() {
  $(".section-up").click(function() {
    var oldOrder = parseInt($(this).attr('data-order'));
    var newOrder = oldOrder - 1;
    if (oldOrder === 0) return false;
    switchRows(oldOrder, newOrder);
    setArrowsAbility();
    return false;
  });

  $(".section-down").click(function() {
    var oldOrder = parseInt($(this).attr('data-order'));
    var newOrder = oldOrder + 1;
    if (document.getElementById("section-"+newOrder) === null) return false;
    switchRows(oldOrder, newOrder);
    setArrowsAbility();
    return false;
  });

  $('.gallery-minmax').click(function() {
    var elem = $(this);
    var id = elem.data('id');
    if (elem.html().trim() === '-') {
      $('#gallery' + id).hide();
      elem.html('+');
    } else {
      $('#gallery' + id).show();
      elem.html('-');
    }
  });

  setArrowsAbility();
});

function switchRows(oldOrder, newOrder) {
  var sourceRow = $("#section-"+oldOrder);
  var sourceGallery = $("#section-gallery-"+oldOrder);
  var targetRow = $("#section-"+newOrder);
  var targetGallery = $("#section-gallery-"+newOrder);

  $("#section-"+oldOrder+" img").attr('data-order', newOrder);
  $("#section-"+newOrder+" img").attr('data-order', oldOrder);
  sourceRow.attr('id', "section-"+newOrder);
  targetRow.attr('id', "section-"+oldOrder);
  sourceGallery.attr('id', "section-gallery-"+newOrder);
  targetGallery.attr('id', "section-gallery-"+oldOrder);

  if (oldOrder > newOrder) {
    sourceRow.insertBefore(targetRow);
    sourceGallery.insertBefore(targetRow);
  } else {
    sourceGallery.insertAfter(targetGallery);
    sourceRow.insertAfter(targetGallery);
  }

  var json = {changes: {}, commit: 'reorder'};
  json.changes[sourceRow.attr('data-section')] = newOrder;
  json.changes[targetRow.attr('data-section')] = oldOrder;
  $.post('/characters', json);
}

function setArrowsAbility() {
  $(".gallery-header .section-up, .gallery-header .section-down").each(function() {
    if (!$(this).hasClass('disabled-arrow')) return;
    $(this).removeClass('disabled-arrow').addClass('pointer');
  });
  $(".gallery-header .section-up").first().removeClass('pointer').addClass('disabled-arrow');
  $(".gallery-header .section-down").last().removeClass('pointer').addClass('disabled-arrow');
}
