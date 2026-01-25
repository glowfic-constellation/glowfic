/* global gon, createSelect2, processTotal, queryTransform */
$(document).ready(function() {
  createSelect2('#setting_id', {
    ajax: {
      url: '/api/v1/tags',
      data: function(params) {
        const data = queryTransform(params);
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
        const data = queryTransform(params);
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

  createSelect2('#user_id', {
    ajax: {
      url: '/api/v1/users',
      processResults: processTotal('username'),
    },
    placeholder: '— Choose User —',
    allowClear: false,
  });

  createSelect2('#post_id', {
    ajax: {
      url: '/api/v1/posts',
      data: function(params) {
        const data = queryTransform(params);
        data.min = 'true';
        return data;
      },
      processResults: processTotal('subject'),
    },
    placeholder: '— Choose Post —',
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
        const data = queryTransform(params);
        const authorId = $("#author_id").val();
        if (authorId !== '' && typeof authorId !== 'undefined') { data.user_id = authorId; }
        data.dropdown = 'true';
        return data;
      },
      processResults: processTotal('dropdown'),
    },
    placeholder: '— Choose Template —',
    allowClear: true,
  });
});
