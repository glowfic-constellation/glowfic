//= require reorder
/* global bindArrows, bindSortable */
$(document).ready(function() {
  bindArrows($("#reorder-posts-table"), '/api/v1/posts/reorder', 'post_ids');
  bindSortable($("#reorder-posts-table"), '/api/v1/posts/reorder', 'post_ids');
});
