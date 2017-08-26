//= require board_sections.js
/* global bindArrows */
$(document).ready(function() {
  bindArrows($("#reorder-sections-table"), '/api/v1/board_sections/reorder', 'section_ids');
});
