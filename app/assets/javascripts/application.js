// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.widget
//= require jquery-fileupload/basic
//= require tinymce-jquery
//= require select2

$(document).ready(function() {
  $(".chosen-select").select2({
    width: '100%',
    minimumResultsForSearch: 10,
  });

  // Set localStorage if login status has changed
  // storage values are usually strings, cast to be sure
  var loggedInKey = 'loggedIn';
  if (window.gon) {
    var wasLoggedIn = gon.logged_in.toString();
    if (localStorage.getItem(loggedInKey) !== wasLoggedIn) {
      localStorage.setItem(loggedInKey, wasLoggedIn);
    }
  }

  // Watch for login status change
  // Display warning prompting user to reload when it occurs
  window.addEventListener('storage', function(e) {
    // skip non-login-status changes
    if (e.key !== loggedInKey) return;
    // skip creation and deletion of storage key (when someone loads the site for the first time or clears cache)
    if (e.oldValue === null || e.newValue === null) return;

    // find or create the warning box
    var warningBox = $('#login_status_warning');
    if (warningBox.length === 0) {
      warningBox = $('<div class="flash inbox pointer" id="login_status_warning">');
      warningBox.click(function() { $(this).remove(); });
      $('#header').after(warningBox);
    }

    // set the relevant warning text
    var msgText = 'logged ' + (e.newValue === 'true' ? 'in' : 'out');
    warningBox.html('You have <strong>' + msgText + '</strong> in another tab. Please reload before submitting any forms.');
  });
});

function add_parameter(url, param, value) {
  var hash = {};
  var parser = document.createElement('a');

  parser.href = url;

  var parameters = parser.search.split(/\?|&/);

  for (var i=0; i < parameters.length; i++) {
    if (!parameters[i])
      continue;

    var ary = parameters[i].split('=');
    hash[ary[0]] = ary[1];
  }

  hash[param] = value;

  var list = [];
  Object.keys(hash).forEach(function(key) {
    list.push(key + '=' + hash[key]);
  });

  parser.search = '?' + list.join('&');
  return parser.href;
}

function resizeScreenname(screenameBox) {
  screenameBox = $(screenameBox);

  // reset previous CSS for post-editor screenname updates
  screenameBox.css('font-size', '');

  // shrink font-size to decrease box size
  if (screenameBox.height() <= 20) return;
  screenameBox.css('font-size', "87.5%");

  if (screenameBox.height() <= 20) return;
  screenameBox.css('font-size', "75%");
}
