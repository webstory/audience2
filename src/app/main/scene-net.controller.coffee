app = angular.module "audience2"

app.controller "SceneNetController", ($scope, $log, analyzerService) ->

  $scope.refreshNet = ->
    links = $scope.olinks
    scenes = $scope.parsedScript

    $scope.characters = analyzerService.getAllCharactersFromGroupInfo($scope.groupInfo)

    places = analyzerService.getPlaces(scenes)

    $log.debug("Places")
    $log.debug(places)


