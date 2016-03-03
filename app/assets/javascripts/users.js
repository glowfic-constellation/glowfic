$(document).ready(function() {
  $("#user_username").blur(function() { 
    $("#username .alert").text('');
    $("#username .messages").text('');
    validateUsername();
  });

  $("#new_user").submit(function() {
    // Clear existing alerts before validating
    $(".alert").text('');
    $(".messages").text('');

    // Do not submit if any validation fails
    var usernameValid = validateUsername();
    var passwordValid = validatePassword();
    var confirmationValid = validateConfirmation();
    if(!(usernameValid && passwordValid && confirmationValid)) { 
      return false; 
    }
    return true;
  });

  $("#user_per_page").chosen({
    width: '70px',
    disable_search_threshold: 20,
  })

  $("#user_timezone").chosen({width: '250px'});
});

validateUsername = function() {
  var username = $("#user_username").val();
  if(username == '') { 
    $("#username .alert").text("!");
    $("#username .messages").html("<div>Please choose a username.</div>");
    return false;
  } else if (username.length < gon.min || username.length > gon.max) {
    $("#username .alert").text("!");
    $("#username .messages").html("<div>Your username must be between "+gon.min+" and "+gon.max+" characters long.</div>");
    return false;
  }

  $.post('/users/username', {'username':username}, function(resp) {
    if(!resp['username_free']){
      $("#username .alert").text("!");
      $("#username .messages").html("<div>That username has already been taken.</div>");
      return false;
    }
  });

  return true;
};

validatePassword = function() {
  var password = $("#user_password").val();
  if(password == '') {
    $("#password .alert").text("!");
    $("#password .messages").html("<div>Please choose a password.</div>");
    return false;
  }
  return true;
};

validateConfirmation = function() {
  var password = $("#user_password").val();
  var conf = $("#user_password_confirmation").val();
  if(conf == '') {
    $("#conf .alert").text("!");
    $("#conf .messages").html("<div>Please confirm your password.</div>");
    return false;
  } else if (conf != password) {
    $("#conf .alert").text("!");
    $("#conf .messages").html("<div>Your passwords do not match.</div>");
    return false;
  }
  return true;
};
