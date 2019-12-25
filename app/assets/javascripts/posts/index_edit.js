//= require reorder
/* global bindArrows, bindSortable */
$(document).ready(function() {
  bindArrows($("#reorder-sections-table"), '/api/v1/index_sections/reorder', 'section_ids');
  bindSortable($("#reorder-sections-table"), '/api/v1/index_sections/reorder', 'section_ids');

  bindArrows($("#reorder-posts-table"), '/api/v1/index_posts/reorder', 'post_ids');
  bindSortable($("#reorder-posts-table"), '/api/v1/index_posts/reorder', 'post_ids');
});
