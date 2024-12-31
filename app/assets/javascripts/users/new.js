/* global gon */
let duplicateUsername = false;
$(document).ready(function() {
  $("#signup-username .user-alert").hide();
  $("#signup-email .user-alert").hide();
  $("#signup-password .user-alert").hide();
  $("#signup-password-confirmation .user-alert").hide();
  $("#signup-terms .user-alert").hide();

  $("#user_username").blur(function() {
    $("#signup-username .user-alert").hide();
    validateUsername();
  });

  $("#user_email").blur(function() {
    $("#signup-email .user-alert").hide();
    validateEmail();
  });

  $("#user_password").blur(function() {
    $("#signup-password .user-alert").hide();
    validatePassword();
  });

  $("#user_password_confirmation").blur(function() {
    $("#signup-password-confirmation .user-alert").hide();
    validateConfirmation();
  });

  $("#new_user").submit(function() {
    // Clear existing alerts before validating
    $(".user-alert").hide();

    // Do not submit if any validation fails
    const usernameValid = validateUsername();
    const passwordValid = validatePassword();
    const confirmationValid = validateConfirmation();
    const emailValid = validateEmail();
    const tosValid = validateTosAccepted();
    if (!(usernameValid && passwordValid && confirmationValid && emailValid && tosValid)) {
      return false;
    }
    return true;
  });
});

function validateUsername() {
  const usernameBox = $("#user_username");
  const username = usernameBox.val();
  if (username === '') {
    addAlertAfter('username', 'Please choose a username.');
    return false;
  } else if (!usernameBox.get(0).checkValidity()) {
    addAlertAfter('username', "Your username must be between "+usernameBox.attr('minlength')+" and "+usernameBox.attr('maxlength')+" characters long.");
    return false;
  }

  // check for duplicate username in background.
  // FIXME: this is currently racy (we can't return from validateUsername in the AJAX call)
  // so we currently return the last saved value of duplicateUsername, and update for the next call.
  // if the username doesn't change rapidly before the submit, this should be good enough.
  $.authenticatedGet('/api/v1/users', {'q': username, 'match': 'exact'}, function(resp, status, xhr) {
    const total = xhr.getResponseHeader('Total');
    duplicateUsername = total > 0;
    if (duplicateUsername) {
      addAlertAfter('username', 'That username has already been taken.');
    }
  });

  return !duplicateUsername;
}

function validateEmail() {
  const email = $("#user_email");
  if (!email.get(0).checkValidity()) {
    addAlertAfter('email', 'Please enter an email address.');
    return false;
  }
  return true;
}

function validatePassword() {
  return validatePasswordField('password', 'password_confirmation', 'choose');
}

function validateConfirmation() {
  return validatePasswordField('password_confirmation', 'password', 'confirm');
}

function validatePasswordField(primaryField, secondaryField, verb) {
  const primaryBox = $("#user_"+primaryField);
  const primary = primaryBox.val();
  const secondary = $("#user_"+secondaryField).val();
  let success = true;

  const addAfterId = primaryField.replace("_", "-");
  if (primary === '') {
    addAlertAfter(addAfterId, 'Please '+verb+' your password.');
    success = false;
  } else if (!primaryBox.get(0).checkValidity()) {
    addAlertAfter(addAfterId, "Your password must be at least "+primaryBox.attr('minlength')+" characters long.");
    success = false;
  }

  if (secondary !== primary) {
    addAlertAfter('password-confirmation', 'Your passwords do not match.');
    success = false;
  }

  return success;
}

function validateTosAccepted() {
  const success = $("#tos").is(':checked');
  if (!success) addAlertAfter('terms', 'You must accept the Terms of Service to use the Constellation.');
  return success;
}

function addAlertAfter(id, message) {
  $("#signup-" + id + " .user-alert span.msg").text(message);
  $("#signup-" + id + " .user-alert").show();
}
