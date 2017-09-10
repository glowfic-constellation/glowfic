function addUploadedIcon(url, s3_key, data, fileInput) {
  $("#icon_conf").show();
  $("#icon_url_field").hide();
  $("#icon_url").hide().val(url);
  $("#icon_s3_key").val(s3_key);
  $("#loading").hide();
  $("#edit-icon").attr('src', url).show().removeClass('uploading-icon');
}

function setLoadingIcon(fileInput) {
  $("#edit-icon").hide().addClass('uploading-icon');
  $("#loading").show();
}
