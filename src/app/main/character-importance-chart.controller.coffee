app = angular.module "audience2"

app.controller "CharacterImportanceChartController", ($scope, $log, analyzerService) ->
  $scope.chartoptions = {
    chart:
      type: 'stackedAreaChart'
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
      showXAxis: false
      interpolate: "step"
      clipEdge: true
      transitionDuration: 500
    title:
      enable: true
      text: "Character Importance"
    subtitle:
      enable: false
    refreshDataOnly: false
  }

  sceneTitles = []

  $scope.refresh = ->
    ###
    CI chart update
    ###
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

    ###
    Closeness Table
    ###
    $scope.closenessTable = []

    $scope.closenessTable.push(["*"].concat($scope.characters)) # Column Header

    for c1 in $scope.characters
      row = [c1]
      $scope.closenessTable.push(row)
      c1_appear = _.pluck(_.filter(scenes, (n) -> _.includes(n.characters, c1)),'sceneNo')

      for c2 in $scope.characters
        c2_appear = _.pluck(_.filter(scenes, (n) -> _.includes(n.characters, c2)),'sceneNo')
        c1_and_c2 = _.intersection(c1_appear, c2_appear)
        c1_or_c2 = _.union(c1_appear, c2_appear)
        row.push(Math.round(c1_and_c2.length / (c1_or_c2.length + 0.0001) * 100))


