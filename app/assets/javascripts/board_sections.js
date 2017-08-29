//= require reorder
/* global bindArrows */
$(document).ready(function() {
  bindArrows($("#reorder-posts-table"), '/api/v1/posts/reorder', 'post_ids');
});
