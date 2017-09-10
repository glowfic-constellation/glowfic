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
