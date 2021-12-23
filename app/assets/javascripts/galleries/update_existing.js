/* exported addUploadedIcon, setLoadingIcon */

function addUploadedIcon(url, s3Key, _data, _fileInput) {
  $(".icon_conf").show();
  $(".icon_url_field").hide();
  $("#icon_url").hide().val(url);
  $("#icon_s3_key").val(s3Key);
  const iconID= $("#icon_id").val();
  $("#loading-"+iconID).hide();
  $("#icon-"+iconID).attr('src', url).show().removeClass('uploading-icon');
}

function setLoadingIcon(_fileInput) {
  const iconID= $("#icon_id").val();
  $("#icon-"+iconID).hide().addClass('uploading-icon');
  $("#loading-"+iconID).show();
}
