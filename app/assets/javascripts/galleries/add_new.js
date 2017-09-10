/* global deleteUnusedIcons */
var done = 0;
var total = 0;
var failed = 0;

$(document).ready(function() {
  fixButtons();
  $(".icon-row td:has(input)").each(function() {
    $(this).keydown(processDirectionalKey);
  });
});

function processDirectionalKey(event) {
  var keyLeft = 37,
    keyUp = 38,
    keyRight = 39,
    keyDown = 40;
  if ([keyLeft, keyUp, keyRight, keyDown].indexOf(event.which) < 0) return;
  var input = $('input', this);
  if (input.get(0).type !== 'text') return;

  var caret = input.get(0).selectionStart;
  var length = input.val().length;
  var index = $(this).closest('td').index();

  var consume = false;
  switch (event.which) {
  case keyLeft:
    if (caret === 0) {
      $(this).closest('td').prev().find('input').focus();
      consume = true;
    }
    break;
  case keyRight:
    if (caret >= length) {
      $(this).closest('td').next().find('input').focus();
      consume = true;
    }
    break;
  case keyUp:
    $(this).closest('tr').prev('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  case keyDown:
    $(this).closest('tr').next('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  }
  if (consume) event.preventDefault();
}

function fixButtons() {
  $(".icon-row-add").hide().unbind();
  $(".icon-row-add").last().show();
  $(".icon-row-rem").show();
  $(".icon-row-rem").first().hide();
  bindAdd();
  bindRem();
  $("#icon-table tr.icon-row:odd td").removeClass('even').addClass("odd");
  $("#icon-table tr.icon-row:even td").removeClass('odd').addClass("even");
}

function bindAdd() {
  $(".icon-row-add").click(function() {
    addNewRow();
    fixButtons();
  });
}

function addNewRow() {
  var oldRow = $(".icon-row:last");
  var newRow = oldRow.clone();
  var index = oldRow.data('index') + 1;
  newRow.data('index', index);

  // clear all input values in the clone
  var inputs = newRow.find('input');
  inputs.val('');

  // clear preview icon
  newRow.find(".preview-icon").attr('src', '').attr('title', '').attr('alt', '');

  // handle the URL field specially
  // because uploads have special UI
  var urlField = inputs.first();
  newRow.find('.conf').remove();
  urlField.show();
  urlField.attr('id', 'icons_'+index+'_url');

  newRow.insertBefore($(".submit-row"));
  $("td:has(input)", newRow).each(function() {
    $(this).keydown(processDirectionalKey);
  });
  return index;
}

function bindRem() {
  $(".icon-row-rem").click(function() {
    var remRow = $(this).parent().parent();
    var removingKey = $(remRow.find('input')[1]).val();
    remRow.remove();
    fixButtons();
    if (removingKey !== '') { deleteUnusedIcons([removingKey]); }
  });
}

function cleanUpRows() {
  $(".icon-row").each(function() {
    var anySet = false;
    if ($(this).find('.conf').length > 0) return;
    $(this).find('input').each(function() {
      if ($(this).val() !== '') {
        anySet = true;
        return false;
      }
    });
    if (!anySet) $(this).remove();
  });
  $(".icon-row").each(function(index) {
    $(this).data('index', index);
    $(this).find('input').first().attr('id', 'icons_'+index+'_url');
  });
  fixButtons();
}

function addUploadedIcon(url, key, data, fileInput) {
  done += 1;
  updateBox();

  // create hidden field
  var iconIndex = addNewRow();
  var row = $(".icon-row").filter(function() { return $(this).data('index') === iconIndex; });
  var urlInput = $("#icons_"+iconIndex+"_url");
  var urlCell = $(urlInput.parents('td:first'));
  urlInput.hide().val(url);
  row.find("input[id$='_s3_key']").val(key);
  urlCell.find('.conf').remove();

  // update keyword box with data.files[0].name minus file extension
  var keyword = data.files[0].name;
  var fileExt = keyword.split('.').slice(-1)[0];
  if (fileExt !== keyword)
    keyword = keyword.replace('.'+fileExt, '');
  row.find("input[id$='_keyword']").val(keyword);

  // Display a preview of the uploaded icon for the user
  row.find(".preview-icon").attr('src', url).attr('title', keyword).attr('alt', keyword);

  var uploaded = ' Uploaded ' + data.files[0].name;
  row.find("input[id$='_filename']").val(data.files[0].name);
  urlCell.append("<span class='conf'><img src='/images/accept.png' alt='' title='Successfully uploaded' class='vmid' />"+uploaded+"</span>");
  cleanUpRows();
}

function addCallback() {
  total += 1;
  updateBox();
}

function failCallback() {
  failed += 1;
  done += 1;
  updateBox();
}

function updateBox() {
  var progressBox = $(".progress-box");
  if (!progressBox) return;
  var progress = parseInt(done / total * 100, 10);
  progressBox.html(done.toString() + ' / ' + total.toString() + ' (' + progress + '%) ');
  if (failed) {
    progressBox.append($("<span style='color: #f00;'>").append(failed.toString() + " failed"));
  }
}
