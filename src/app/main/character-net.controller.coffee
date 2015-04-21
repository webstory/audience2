app = angular.module "audience2"

app.controller "CharacterNetController", ($scope, analyzerService) ->
  $scope.draw = ->
    links = null
    if $scope.clustered == true
      links = angular.copy($scope.glinks)
    else
      links = angular.copy($scope.olinks)

    drawGraph("#character_net", links, $("#character_net").width(), $("#character_net").height())
