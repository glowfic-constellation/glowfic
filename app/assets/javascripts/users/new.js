$(document).ready(function() {
  $("#user_username").blur(function() { 
    $("#username .alert").remove();
    validateUsername();
  });

  $("#user_email").blur(function() { 
    $("#email .alert").remove();
    validateEmail();
  });

  $("#user_password").blur(function() { 
    $("#password .alert").remove();
    validatePassword();
  });

  $("#user_password_confirmation").blur(function() { 
    $("#conf .alert").remove();
    validateConfirmation();
  });

  $("#new_user").submit(function() {
    // Clear existing alerts before validating
    $(".alert").remove();

    // Do not submit if any validation fails
    var usernameValid = validateUsername();
    var passwordValid = validatePassword();
    var confirmationValid = validateConfirmation();
    var emailValid = validateEmail();
    if(!(usernameValid && passwordValid && confirmationValid && emailValid)) { 
      return false; 
    }
    return true;
  });
});

validateUsername = function() {
  var username = $("#user_username").val();
  if(username == '') { 
    addAlertAfter('user_username', 'Please choose a username.');
    return false;
  } else if (username.length < gon.min || username.length > gon.max) {
    addAlertAfter('user_username', "Your username must be between "+gon.min+" and "+gon.max+" characters long.");
    return false;
  }

  $.post('/users/username', {'username':username}, function(resp) {
    if(!resp.username_free){
      addAlertAfter('user_username', 'That username has already been taken.');
      return false;
    }
  });

  return true;
};

validateEmail = function() {
  var email = $("#user_email").val();
  if(email == '') { 
    addAlertAfter('user_email', 'Please enter an email address.');
    return false;
  }
  return true;
};

validatePassword = function() {
  var password = $("#user_password").val();
  var conf = $("#user_password_confirmation").val();
  var success = true;
  if(password == '') {
    addAlertAfter('user_password', 'Please choose a password.');
    success = false;
  }
  if (conf != password) {
    $("#conf .alert").remove();
    addAlertAfter('user_password_confirmation', 'Your passwords do not match.');
    success = false;
  }
  return success;
};

validateConfirmation = function() {
  var password = $("#user_password").val();
  var conf = $("#user_password_confirmation").val();
  var success = true;
  if(conf == '') {
    addAlertAfter('user_password_confirmation', 'Please confirm your password.');
    success = false;
  }
  if (conf != password) {
    addAlertAfter('user_password_confirmation', 'Your passwords do not match.');
    success = false;
  }
  return success;
};

addAlertAfter = function(id, message) {
  image = "<img src='/images/exclamation.png' alt='!' title='' class='vmid' /> "
  $("#"+id).after("<div class='alert' style='margin: 2px 0px;'>" + image + message + "</div>");
};
