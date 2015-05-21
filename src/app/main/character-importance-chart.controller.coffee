app = angular.module "audience2"

app.controller "CharacterImportanceChartController", ($scope, $log, analyzerService) ->
  $scope.chartoptions = {
    chart:
      type: 'lineChart'
      height: 500
      x: (d) -> d.scene_number
      y: (d) -> d.value
      useInteractiveGuideline: true
      xAxis:
        axisLabel: 'Scenes'
        tickFormat: (d) -> "#{d}: #{sceneTitles[d-1]}"
      yAxis:
        axisLabel: 'CI'
        tickFormat: (d) -> d3.format('.02f')(d)
    title:
      enable: true
      text: "Character Importance"
    subtitle:
      enable: false
    refreshDataOnly: false
  }

  sceneTitles = []

  $scope.refresh = ->
    links = $scope.olinks
    scenes = $scope.parsedScript
    sceneTitles = _.pluck(scenes, "sceneTitle")

    $scope.characters = [].concat($scope.groupInfo.main.characters).concat($scope.groupInfo.sub.characters)

    data = []
    for character in $scope.characters
      scene_ci = []
      data.push {
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

    $scope.data = data