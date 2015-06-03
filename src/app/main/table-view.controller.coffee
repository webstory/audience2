angular.module "audience2"
.controller "TableViewController", ($scope, analyzerService) ->
  $scope.refresh = ->
    scenes = $scope.$parent.parsedScript
    if !scenes? then return

    $scope.talkDegree = analyzerService.buildTalkDegreeDelta($scope.talkDegree)

    $scope.group1Index = $scope.groupInfo.main.index
    $scope.group2Index = $scope.groupInfo.sub.index
    $scope.group3Index = $scope.groupInfo.extra.index

    ###
    Compute Degree Centrality
    ###
    $scope.DC = analyzerService.getDegreeCentrality($scope.talkDegree, $scope.groupInfo)

    ###
    Extract group weight
    ###
    $scope.groupVal = [0,0,0,0,0,0,0,0,0]
    $scope.totalWeight = (_($scope.talkDegree).reduce ((a, d) -> (a + d.listen)), 0)

    $scope.groupVal[0] = $scope.glinks[1] # 4) Main -> Sub
    $scope.groupVal[1] = $scope.glinks[2] # 5) Main -> Extra
    $scope.groupVal[2] = $scope.glinks[6] # 6) Sub -> Main
    $scope.groupVal[3] = $scope.glinks[8] # 7) Sub -> Extra
    $scope.groupVal[4] = $scope.glinks[3] # 8) Extra -> Main
    $scope.groupVal[5] = $scope.glinks[4] # 9) Extra -> Sub
    $scope.groupVal[6] = $scope.glinks[0] # 10) Main -> Main
    $scope.groupVal[7] = $scope.glinks[7] # 11) Sub -> Sub
    $scope.groupVal[8] = $scope.glinks[5] # 12) Extra -> Extra
