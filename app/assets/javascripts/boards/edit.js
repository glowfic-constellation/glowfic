//= require board_sections.js
/* global bindArrows, bindSortable */
$(document).ready(function() {
  bindArrows($("#reorder-sections-table"), '/api/v1/subcontinuities/reorder', 'section_ids');
  bindSortable($("#reorder-sections-table"), '/api/v1/subcontinuities/reorder', 'section_ids');
});
