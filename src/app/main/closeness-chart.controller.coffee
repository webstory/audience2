app = angular.module "audience2"

app.controller "ClosenessChartController", ($scope, $log, analyzerService) ->
  $scope.chartoptions = {
    chart:
      type: 'lineChart'
      height: 500
      x: (d) -> d.x
      y: (d) -> d.y
      useInteractiveGuideline: true
      xAxis:
        axisLabel: 'Scenes'
      yAxis:
        axisLabel: 'Closeness'
    title:
      enable: false
    subtitle:
      enable: false
  }


  $scope.data = []


  $scope.refresh = ->
    links = $scope.olinks
    scenes = $scope.parsedScript

    $scope.characters = analyzerService.getAllCharactersFromGroupInfo($scope.groupInfo)

    for scene in scenes
      data = {
        values: scene
      }

      $scope.data.push {}




