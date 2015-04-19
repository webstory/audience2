angular.module "audience2"
  .controller "authCtrl", ($scope, $modal, authService, $log) ->
    $scope.userName = authService.getUserName()
    $scope.isLogged = authService.isLogged()

    $scope.$on "login.success", (ev, message) ->
      $scope.userName = message.user_name
      $scope.isLogged = true

    $scope.$on "login.failed", (ev, message) ->
      $scope.userName = "guset"
      $scope.isLogged = false
      $modal.open
        templateUrl: "components/templates/login_failed.tmpl.html"
        backdrop: 'static'
        size: 'sm'
        controller: ($scope, $modalInstance) ->
          $scope.message = message
          $scope.ok = -> $modalInstance.close()


    $scope.login = ->
      authService.login($scope.user_id, $scope.pw)

    $scope.logout = ->
      authService.logout()
      $scope.isLogged = false