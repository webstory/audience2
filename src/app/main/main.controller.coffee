app = angular.module "audience2"

app.controller "MainCtrl", ($scope, $q, $log, hljsService, analyzerService) ->
  $scope.editorOptions =
    lineNumbers: true
    lineWrapping: true
    mode: "finaldraft"
    theme:"paraiso-light"

  $scope.codemirrorLoaded = ($editor) ->
    $scope.cm = $editor
    $scope.doc = $editor.getDoc()


  $scope.analyze = ->
    scenes = analyzerService.parseScript(@.cm)
    $scope.parsedScript = scenes

    ###
    Update JSON view
    ###
    $scope.jsonview = JSON.stringify(scenes, null, 4) # Tab width 4

    # Prior view before finish highlighting
    $("#jsonview").html($scope.jsonview)

    # NOTE: ng-bind-html is not working(unsafe error)
    # #jsonview element must be <pre> element. Otherwise, it is not formatted.

    deferred = $q.defer()
    deferred.resolve ->
      hljsService.highlight('json',$scope.jsonview).value

    deferred.promise.then (res) ->
      $("#jsonview").html(res)

    ###
    After parse end, scene range must reset.
    ###
    $scope.scene_start = 1
    $scope.scene_end = scenes.length

    $scope.refreshNet()

  $scope.$watch 'scene_start + scene_end', ->
    scenes = $scope.parsedScript
    if !scenes? then return

    $scope.scene_start = _.min([$scope.scene_end, _.max([$scope.scene_start, 1])])
    $scope.scene_end = _.max([0, _.min([$scope.scene_end, scenes.length])])

    $scope.sceneStartTitle = "#{scenes[$scope.scene_start-1].sceneTitle} (#{scenes[$scope.scene_start-1].lineNo})"
    $scope.sceneEndTitle = "#{scenes[$scope.scene_end-1].sceneTitle} (#{scenes[$scope.scene_end-1].lineNo})"

  $scope.refreshNet = ->
    scenes = $scope.parsedScript.slice($scope.scene_start - 1, $scope.scene_end)
    if !scenes? then return

    ###
    Compute Non-Cluster(Original)
    !!WARNING!!
    $scope.olinks used in child scope.
    ###
    $scope.olinks = analyzerService.buildCharacterNet(scenes)
    $scope.talkDegree = analyzerService.buildTalkDegree(scenes)
    $scope.groupInfo = analyzerService.getCharacterGroups($scope.talkDegree)

    ###
    Compute Clustered Character net
    ###
    $scope.glinks = analyzerService.buildClusteredCharacterNet(scenes, $scope.groupInfo)

