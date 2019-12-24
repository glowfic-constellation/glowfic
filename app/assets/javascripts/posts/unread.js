/* global processResults, queryTransform */
$(document).ready(function() {
  $("#board_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/boards',
      dataType: 'json',
      data: queryTransform,
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'name');
      },
      cache: true
    },
    placeholder: '— Choose Continuity —',
    allowClear: true,
    width: '100%'
  });
});
