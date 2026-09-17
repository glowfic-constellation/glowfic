/* Fills in the CSRF token on forms rendered without one.
 *
 * A page held in a shared cache cannot carry a token: it is tied to the
 * session of whoever caused the render. Such pages ship the form with no
 * token field and mark it `data-needs-csrf`; this fetches a token bound to
 * this browser's own session and inserts it before the form can be used.
 *
 * The fetch is deliberately not awaited on page load beyond inserting the
 * field — the form is not usable until a reader has typed into it, which is
 * far longer than the request takes.
 */
$(document).ready(function() {
  var forms = $('form[data-needs-csrf="true"]');
  if (forms.length === 0) { return; }

  $.ajax({
    url: '/csrf',
    dataType: 'json',
    // Same-origin only; the endpoint sends no CORS header, so a cross-origin
    // caller could not read the reply in any case.
    success: function(data) {
      if (!data || !data.token) { return; }
      forms.each(function() {
        var form = $(this);
        // Guard against a double insert if this ever runs twice.
        if (form.find('input[name="authenticity_token"]').length > 0) { return; }
        $('<input>').attr({
          type: 'hidden',
          name: 'authenticity_token',
          value: data.token
        }).appendTo(form);
      });
      // Anything else on the page that reads the token from the meta tag
      // (jquery-ujs, for one) should see the same value.
      if ($('meta[name="csrf-token"]').length === 0) {
        $('<meta>').attr({ name: 'csrf-token', content: data.token }).appendTo('head');
      } else {
        $('meta[name="csrf-token"]').attr('content', data.token);
      }
    }
  });
});
