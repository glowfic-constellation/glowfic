/* global gon, processResults, queryTransform */
$(document).ready(function() {
  $("#index_post_post_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/posts',
      dataType: 'json',
      data: function(params) { return queryTransform(params); },
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'subject');
      },
      cache: true
    },
    placeholder: '— Choose Post —',
    allowClear: true,
    width: '100%'
  });
});
