/* global createSelect2, processResults */
$(document).ready(function() {
  createSelect2('#board_id', {
    ajax: {
      url: '/api/v1/boards',
      processResults: function(data, params) {
        const total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'name');
      },
    },
    placeholder: '— Choose Continuity —',
    allowClear: true,
  });
});
