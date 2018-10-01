$(document).ready(function() {
  $("#block_blocked_user_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/users',
      dataType: 'json',
      data: queryTransform,
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
