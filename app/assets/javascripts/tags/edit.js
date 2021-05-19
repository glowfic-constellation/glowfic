/* global createTagSelect */
$(document).ready(function() {
  const tagID = $("#setting_parent_setting_ids").data('tag-id');
  createTagSelect("Setting", "parent_setting", "setting", {tag_id: tagID});
});
