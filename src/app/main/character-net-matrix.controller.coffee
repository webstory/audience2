app = angular.module "audience2"

app.controller "CharacterNetMatrixController", ($scope, $log, analyzerService) ->
  ###
  Compute Matrix table with title
  ###
  $scope.netSortBy = "degree"

  $scope.refreshMatrix = ->
    links = $scope.olinks

    if $scope.netSortBy == "degree"
      characters = analyzerService.getAllCharactersFromGroupInfo($scope.groupInfo)
    else if $scope.netSortBy == "plotTime"
      characters = []
      talks = analyzerService.buildTalkMatrix($scope.parsedScript)
      for talk in _.sortBy(talks, (t) -> t.line)
        character = talk.teller
        if not _.include(characters, character)
          characters.push(character)
    else characters = []



    $scope.charNetTable = []

    $scope.charNetTable.push(["*"].concat(characters)) # Column Header

    for teller in characters
      row = [teller]
      $scope.charNetTable.push(row)

      for listener in characters
        finder = _.findWhere(links, {"source":teller, "target":listener})
        row.push(finder?.degree || 0)

