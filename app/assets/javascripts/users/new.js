/* global gon */
$(document).ready(function() {
  $("#user_username").blur(function() {
    $("#username .alert").hide();
    validateUsername();
  });

  $("#user_email").blur(function() {
    $("#email .alert").hide();
    validateEmail();
  });

  $("#user_password").blur(function() {
    $("#password .alert").hide();
    validatePassword();
  });

  $("#user_password_confirmation").blur(function() {
    $("#conf .alert").hide();
    validateConfirmation();
  });

  $("#new_user").submit(function() {
    // Clear existing alerts before validating
    $(".alert").hide();

    // Do not submit if any validation fails
    var usernameValid = validateUsername();
    var passwordValid = validatePassword();
    var confirmationValid = validateConfirmation();
    var emailValid = validateEmail();
    var tosValid = validateTosAccepted();
    if (!(usernameValid && passwordValid && confirmationValid && emailValid && tosValid)) {
      return false;
    }
    return true;
  });
});

function validateUsername() {
  var username = $("#user_username").val();
  if (username === '') {
    addAlertAfter('username', 'Please choose a username.');
    return false;
  } else if (username.length < gon.min || username.length > gon.max) {
    addAlertAfter('username', "Your username must be between "+gon.min+" and "+gon.max+" characters long.");
    return false;
  }

  $.get('/api/v1/users', {'q': username, 'match': 'exact'}, function(resp, status, xhr) {
    var total = xhr.getResponseHeader('Total');
    if (total > 0) {
      addAlertAfter('username', 'That username has already been taken.');
      return false; // TODO: actually return false from validateUsername
    }
  });

  return true;
}

function validateEmail() {
  var email = $("#user_email").val();
  if (email === '') {
    addAlertAfter('email', 'Please enter an email address.');
    return false;
  }
  return true;
}

function validatePassword() {
  var password = $("#user_password").val();
  var conf = $("#user_password_confirmation").val();
  var success = true;
  if (password === '') {
    addAlertAfter('password', 'Please choose a password.');
    success = false;
  }
  if (conf !== password) {
    addAlertAfter('conf', 'Your passwords do not match.');
    success = false;
  }
  return success;
}

function validateConfirmation() {
  var password = $("#user_password").val();
  var conf = $("#user_password_confirmation").val();
  var success = true;
  if (conf === '') {
    addAlertAfter('conf', 'Please confirm your password.');
    success = false;
  }
  if (conf !== password) {
    addAlertAfter('conf', 'Your passwords do not match.');
    success = false;
  }
  return success;
}

function validateTosAccepted() {
  var success = $("#tos").is(':checked');
  if (!success) addAlertAfter('terms', 'You must accept the Terms of Service to use the Constellation.');
  return success;
}

function addAlertAfter(id, message) {
  $("#" + id + " .alert span.msg").text(message);
  $("#" + id + " .alert").show();
}
