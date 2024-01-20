/* global gon */
$(document).ready(function() {
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
  const username = $("#user_username").val();
  if (username === '') {
    addAlertAfter('username', 'Please choose a username.');
    return false;
  } else if (username.length < gon.min || username.length > gon.max) {
    addAlertAfter('username', "Your username must be between "+gon.min+" and "+gon.max+" characters long.");
    return false;
  }

  // eslint-disable-next-line consistent-return
  $.authenticatedGet('/api/v1/users', {'q': username, 'match': 'exact'}, function(resp, status, xhr) {
    const total = xhr.getResponseHeader('Total');
    if (total > 0) {
      addAlertAfter('username', 'That username has already been taken.');
      return false; // TODO: actually return false from validateUsername
    }
  });

  return true;
}

function validateEmail() {
  const email = $("#user_email").val();
  if (email === '') {
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
  const primary = $("#user_"+primaryField).val();
  const secondary = $("#user_"+secondaryField).val();
  let success = true;

  if (primary === '') {
    const addAfterId = primaryField.replace("_", "-");
    addAlertAfter(addAfterId, 'Please '+verb+' your password.');
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
