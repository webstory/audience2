var app = angular.module("audience2");

app.factory("authService", function($rootScope, $http, $window, $log, serverConfig) {
  var setSessionKey = function(session_key) {
    $window.sessionStorage.setItem("session_key", session_key);
  }

  var setUserName = function(user_name) {
    $window.sessionStorage.setItem("user_name", user_name); 
  }

  var server_url = serverConfig.url;

  return {
    isLogged: function() {
      return !!this.getSessionKey();
    },

    login: function(id, pw) {
      var enc_pw = CryptoJS.SHA256(pw).toString(CryptoJS.enc.Base64);

      return $http({
        method: "POST",
        url: server_url,
        data: {
          id: id,
          pw: enc_pw
        },
        params: {
          method: "login"
        }
      }).success(function(data) {
        $log.debug(data);
        setSessionKey(data.message.session_key);
        setUserName(data.message.user_name);
        $rootScope.$broadcast("login.success", data.message);
      }).error(function(data, status) {
        $rootScope.$broadcast("login.failed", data.message);
        $log.error(data);
      });
    },

    logout: function() {
      $http({
        method: "POST",
        url: server_url,
        data: {
          key: this.getSessionKey()
        },
        params: {
          method: "logout"
        }
      }).success(function(data) {
        setSessionKey(null);
        setUserName("guest");
        $log.debug(data);
      });
    },

    echoMessage: function(message) {
      $http({
        method: "POST",
        url: server_url,
        data: {
          key: this.getSessionKey(),
          message: message
        },
        params: {
          method: "echo"
        }
      }).success(function(data) {
        $log.debug(data);
        this.message = data.message;
      });

      return message;
    },

    getSessionKey: function() {
      return $window.sessionStorage.getItem("session_key");
    },

    getUserName: function() {
      return $window.sessionStorage.getItem("user_name");
    }

  }
});
