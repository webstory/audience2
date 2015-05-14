app = angular.module "audience2"

app.controller "SceneNetController", ($scope, $log, analyzerService) ->
  ###
  Compute Matrix table with title
  ###
  $scope.netSortBy = "degree"

  $scope.refreshNet = ->
    links = $scope.olinks

    $scope.characters = analyzerService.getAllCharactersFromGroupInfo($scope.groupInfo)

