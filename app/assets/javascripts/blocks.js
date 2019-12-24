/* global processResults, queryTransform */
$(document).ready(function() {
  $("#block_blocked_user_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/users',
      dataType: 'json',
      data: function(params) {
        var data = queryTransform(params);
        data.hide_unblockable = true;
        return data;
      },
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'username');
      },
      cache: true
    },
    placeholder: '— Choose User —',
    allowClear: true,
    width: '100%'
  });
});
