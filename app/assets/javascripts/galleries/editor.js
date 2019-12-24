/* global createTagSelect, gon */
$(document).ready(function() {
  createTagSelect("GalleryGroup", "gallery_group", "gallery", {user_id: gon.user_id});
});
