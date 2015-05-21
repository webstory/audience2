app = angular.module "audience2"

app.controller "CharacterImportanceChartController", ($scope, $log, analyzerService) ->
  $scope.chartoptions = {
    chart:
      #type: 'lineWithFocusChart'
      type: 'lineChart'
      height: 500
      x: (d) -> d.scene_number
      y: (d) -> d.value
      useInteractiveGuideline: true
      xAxis:
        axisLabel: 'Scenes'
      yAxis:
        axisLabel: 'CI'
        tickFormat: (d) -> d3.format('.02f')(d)
      x2Axis: {}
      y2Axis: {}
    title:
      enable: true
      text: "Character Importance"
    subtitle:
      enable: false
    refreshDataOnly: false
  }

  $scope.refresh = ->
    $scope.data = []
    links = $scope.olinks
    scenes = $scope.parsedScript

    $scope.characters = analyzerService.getAllCharactersFromGroupInfo($scope.groupInfo)


    for character, char_index in $scope.characters
      scene_ci = []
      $scope.data.push {
        values: scene_ci
        key: character
        disabled: true
      }

      for scene, scene_index in scenes
        talk = 0
        talk_total = 0.001

        for d in scene.dialogues
          if d.character == character
            talk += d.dialogue.length

          talk_total += d.dialogue.length

        scene_ci.push({ value: talk / talk_total, scene_number: scene_index + 1})
