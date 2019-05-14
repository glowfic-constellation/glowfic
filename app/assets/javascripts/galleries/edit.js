$(document).ready(function() {
  var submitButton = $('.submit-button input');
  submitButton.on('mousedown', warnIfDeleting);
});

function addUploadedIcon(url, s3_key, data, fileInput) {
  var iconId = fileInput.data('icon-id');
  var iconRow = "#icon-row-" + iconId;
  $(iconRow + " .icon_conf").show();
  $(iconRow + " .icon_url_field").hide();
  $(iconRow).find('input[id$=_url]').first().hide().val(url);
  $(iconRow).find('input[id$=_s3_key]').first().hide().val(s3_key);
  $("#loading-"+iconId).hide();
  $("#icon-"+iconId).attr('src', url).show().removeClass('uploading-icon');
}

function setLoadingIcon(fileInput) {
  var iconId = fileInput.data('icon-id');
  $("#icon-"+iconId).hide().addClass('uploading-icon');
  $("#loading-"+iconId).show();
}

function warnIfDeleting() {
  var icons = $('.gallery-icon-editor');
  var deletingIcons = icons.filter(function() {
    var destroyInput = $('.gallery-icon-destroy input[type="checkbox"]', this);
    return destroyInput.prop('checked');
  });
  $(this).data('confirm', null);
  if (deletingIcons.length === 0) return;

  var iconKeywords = deletingIcons.map(function() {
    return $('.gallery-icon-keyword input', this).val();
  });

  var confirmString = 'Are you sure you want to delete ' + deletingIcons.length + ' icon' + (deletingIcons.length === 1 ? '' : 's') + '?';
  confirmString += "\n\n";
  confirmString += iconKeywords.get().join(', ');
  $(this).data('confirm', confirmString);
}
