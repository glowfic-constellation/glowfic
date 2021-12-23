/* exported addUploadedIcon, setLoadingIcon */

$(document).ready(function() {
  const submitButton = $('.submit-button input');
  submitButton.on('mousedown', warnIfDeleting);
});

function addUploadedIcon(url, s3Key, data, fileInput) {
  const iconId = fileInput.data('icon-id');
  const iconRow = "#icon-row-" + iconId;
  $(iconRow + " .icon_conf").show();
  $(iconRow + " .icon_url_field").hide();
  $(iconRow).find('input[id$=_url]').first().hide().val(url);
  $(iconRow).find('input[id$=_s3_key]').first().hide().val(s3Key);
  $("#loading-"+iconId).hide();
  $("#icon-"+iconId).attr('src', url).show().removeClass('uploading-icon');
}

function setLoadingIcon(fileInput) {
  const iconId = fileInput.data('icon-id');
  $("#icon-"+iconId).hide().addClass('uploading-icon');
  $("#loading-"+iconId).show();
}

function warnIfDeleting() {
  const icons = $('.gallery-icon-editor');
  const deletingIcons = icons.filter(function() {
    const destroyInput = $('.gallery-icon-destroy input[type="checkbox"]', this);
    return destroyInput.prop('checked');
  });
  $(this).data('confirm', null);
  if (deletingIcons.length === 0) return;

  const iconKeywords = deletingIcons.map(function() {
    return $('.gallery-icon-keyword input', this).val();
  });

  let confirmString = 'Are you sure you want to delete ' + deletingIcons.length + ' icon' + (deletingIcons.length === 1 ? '' : 's') + '?';
  confirmString += "\n\n";
  confirmString += iconKeywords.get().join(', ');
  $(this).data('confirm', confirmString);
}
