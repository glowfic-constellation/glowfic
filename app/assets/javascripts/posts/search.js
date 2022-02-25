/* global gon, createSelect2, processTotal, queryTransform */
$(document).ready(function() {
  createSelect2('#setting_id', {
    ajax: {
      url: '/api/v1/tags',
      data: function(params) {
        var data = queryTransform(params);
        data.t = 'Setting';
        return data;
      },
      processResults: processTotal(),
    },
    placeholder: '— Choose Setting —',
    allowClear: true,
  });

  createSelect2('#character_id', {
    ajax: {
      url: '/api/v1/characters',
      data: function(params) {
        var data = queryTransform(params);
        if (typeof gon !== 'undefined') data.post_id = gon.post_id;
        return data;
      },
      processResults: processTotal('selector_name'),
    },
    placeholder: '— Choose Character —',
    allowClear: true,
  });

  createSelect2('#author_id', {
    ajax: {
      url: '/api/v1/users',
      processResults: processTotal('username'),
    },
    placeholder: '— Choose Author —',
    allowClear: true,
  });

  createSelect2('#board_id', {
    ajax: {
      url: '/api/v1/boards',
      processResults: processTotal('name'),
    },
    placeholder: '— Choose Continuity —',
    allowClear: true,
  });

  createSelect2('#template_id', {
    ajax: {
      url: '/api/v1/templates',
      data: function(params) {
        var data = queryTransform(params);
        var authorId = $("#author_id").val();
        if (authorId !== '' && typeof authorId !== 'undefined') { data.user_id = authorId; }
        return data;
      },
      processResults: processTotal('name'),
    },
    placeholder: '— Choose Template —',
    allowClear: true,
  });
});
