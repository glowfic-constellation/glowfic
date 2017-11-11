/* global createTagSelect */
$(document).ready(function() {
  var tagID = $("#tag_parent_setting_ids").data('tag-id');
  createTagSelect("Setting", "parent_setting", "tag", {tag_id: tagID});
});
