app = angular.module "audience2"

app.controller "SceneNetController", ($scope, $log, analyzerService) ->
  $scope.selectedCharacters = []

  $scope.updateAppearance = ->
    scenes = $scope.parsedScript
    sel_chars = $scope.selectedCharacters || []
    appear = null

    if sel_chars.length == 0
      appear = _.filter(scenes, (n) -> n.characters.length == 0)
    else
      appear = scenes

    for c in sel_chars
      c_appear = _.filter(scenes, (n) -> _.includes(n.characters, c))
      appear = _.intersection(appear, c_appear)

    $scope.appearance = appear


  $scope.refreshNet = ->
    links = $scope.olinks
    scenes = $scope.parsedScript

    characters = [].concat($scope.groupInfo.main.characters).concat($scope.groupInfo.sub.characters)
    $scope.characters = []

    for character in characters
      appear = _.pluck(_.filter(scenes, (n) -> _.includes(n.characters, character)),'sceneNo')
      $scope.characters.push({
        name: character
        appear: appear
      })

    ###
    Sorted scene by Characters
    ###
    getWeight = (n) ->
      weight = 0

      for c in n.characters
        if _.includes($scope.groupInfo.main.characters, c)
          weight -= 100
        else if _.includes($scope.groupInfo.sub.characters, c)
          weight -= 10
        else if _.includes($scope.groupInfo.extra.characters, c)
          weight -= 1

      return weight

    $scope.sorted_scene_by_characters = _.sortBy(scenes, getWeight)
