function addUploadedIcon(url, s3_key, data, fileInput) {
  var iconId = fileInput.data('icon-id');
  var iconRow = "#icon-row-" + iconId;
  $(iconRow + " .icon_conf").show();
  $(iconRow + " .icon_url_field").hide();
  $(iconRow).find('input[id$=_url]').first().hide().val(url);
  $(iconRow).find('input[id$=_s3_key]').first().hide().val(s3_key);
  $("#icon-"+iconId).attr('src', url);
}

function setLoadingIcon() {}
