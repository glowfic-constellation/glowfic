//= require board_sections.js
/* global bindArrows, bindSortable */
$(document).ready(function() {
  bindArrows($("#reorder-sections-table"), '/api/v1/board_sections/reorder', 'section_ids');
  bindSortable($("#reorder-sections-table"), '/api/v1/board_sections/reorder', 'section_ids');
});
