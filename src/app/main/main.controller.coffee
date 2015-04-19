angular.module "audience2"
  .controller "MainCtrl", ($scope, $rootScope, $http, $modal, $q, hljsService) ->
    # Initialize Adjustable elements
    $(window).resize ->
      $(".autoresize").each ->
        $(@).height($(window).height() - $(@).position().top - 130)

    $(window).trigger('resize') # Initial resize at first loading

    $scope.editorOptions =
      lineNumbers: true
      lineWrapping: true
      mode: "finaldraft"
      theme:"paraiso-light"

    $scope.codemirrorLoaded = ($editor) ->
      $scope.cm = $editor
      $scope.doc = $editor.getDoc()


    $scope.analyze = ->
      CodeMirror.commands["parseScript"](@.cm, $rootScope)

      ###
      Update JSON view
      ###
      $scope.jsonview = JSON.stringify($rootScope.parsedScript, null, 4) # Tab width 4

      # Prior view before finish highlighting
      $("#jsonview").html($scope.jsonview)

      # NOTE: ng-bind-html is not working(unsafe error)
      # #jsonview element must be <pre> element. Otherwise, it is not formatted.

      deferred = $q.defer()
      deferred.resolve ->
        hljsService.highlight('json',$scope.jsonview).value

      deferred.promise.then (res) ->
        $("#jsonview").html(res)

      scenes = $rootScope.parsedScript

      $scope.scene_start = 1
      $scope.scene_end = scenes.length

      $scope.refreshNet()

      # Call RefreshTableView
      $scope.$broadcast('refreshTableView')

    $rootScope.$watch 'parsedScript', ->
      window.scenes = $rootScope.parsedScript

    $scope.$watch 'scene_start + scene_end', ->
      scenes = $rootScope.parsedScript
      if not scenes? then return

      $scope.scene_start = _.min([$scope.scene_end, _.max([$scope.scene_start, 1])])
      $scope.scene_end = _.max([0, _.min([$scope.scene_end, scenes.length])])

      $scope.sceneStartTitle = "#{scenes[$scope.scene_start-1].sceneTitle} (#{scenes[$scope.scene_start-1].lineNo})"
      $scope.sceneEndTitle = "#{scenes[$scope.scene_end-1].sceneTitle} (#{scenes[$scope.scene_end-1].lineNo})"

    $scope.refreshNet = ->
      scenes = $rootScope.parsedScript.slice($scope.scene_start - 1, $scope.scene_end)
      $rootScope.olinks = []
      $rootScope.glinks = []

      if !scenes? then return

      ###
      Compute Non-Cluster(Original)
      ###
      for scene in scenes
        listeners = scene.characters

        recalcEdge = (links, listeners, dialogue) ->
          teller = dialogue.character
          for listener in listeners
            if teller != listener
              finder = _.findWhere(links, {"source":teller, "target":listener})
              if finder is undefined or finder is null
                links.push
                  source:teller
                  target:listener
                  degree:dialogue.dialogue.length
              else
                finder.degree += dialogue.dialogue.length

          recalcSelfEdge = (links, listeners, dialogue) ->
            teller = dialogue.character
            if listeners.length == 1 # Only self-edged filter
              listener = listeners[0]
              finder = _.findWhere(links, {"source":teller, "target":listener})
              if finder is undefined or finder is null
                links.push
                  source:teller
                  target:listener
                  degree:dialogue.dialogue.length
              else
                finder.degree += dialogue.dialogue.length

          # Workagound: calculating self edge
          recalcSelfEdge(links, listeners, dialogue)

        for dialogue in scene.dialogues
          recalcEdge $rootScope.olinks, listeners, dialogue

      $rootScope.$broadcast('refreshTableView')

      ###
      Compute Clustered Character net
      Bug workaround: Must trigger first refreshTableView
      ###
      for scene in scenes
        groups = ['Main', 'Sub', 'Extra']
        listeners = scene.characters

        recalcGroupEdge = (links, groups, listeners, dialogue) ->
          main  = $rootScope.group1
          sub   = $rootScope.group2
          extra = $rootScope.group3

          character = dialogue.character

          if _.contains(main,  character) then teller = groups[0]
          if _.contains(sub,   character) then teller = groups[1]
          if _.contains(extra, character) then teller = groups[2]

          lgroups = []

          if _.intersection(main,  listeners).length > 0 then lgroups.push groups[0]
          if _.intersection(sub,   listeners).length > 0 then lgroups.push groups[1]
          if _.intersection(extra, listeners).length > 0 then lgroups.push groups[2]

          for lgroup in lgroups
            finder = _.findWhere(links, {"source":teller, "target":lgroup})
            if finder is undefined or finder is null
              links.push
                source:teller
                target:lgroup
                degree:dialogue.dialogue.length
            else
              finder.degree += dialogue.dialogue.length

        for dialogue in scene.dialogues
          recalcGroupEdge $rootScope.glinks, groups, listeners, dialogue

      links = null
      if $scope.clustered == true
        links = $rootScope.glinks
      else
        links = $rootScope.olinks

      console.log "Links"
      console.log links
      drawGraph("#character_net", links, $("#character").width(), $("#character").height())



  .controller "TableViewController", ($scope, $rootScope) ->
    $scope.$on 'refreshTableView', (event, target) ->
      scenes = $rootScope.parsedScript
      $scope.talks = []
      selectedScenes = scenes.slice($scope.scene_start - 1, $scope.scene_end)
      for scene, index in selectedScenes
        sceneNo = index + 1 # Scene number started at 1
        sceneTitle = scene.sceneTitle
        listeners = scene.characters.sort()

        for dialogue in scene.dialogues
          $scope.talks.push
            number: sceneNo
            title: sceneTitle
            line: dialogue.lineNo
            teller: dialogue.character
            listener: listeners
            dialogue: dialogue.dialogue

      # Character centerality analysis
      # Table structure:
      #   <Character> <Tell-length> <Listen-length> <Delta(Listen)>
      talkDegree = []

      for talk in $scope.talks
        teller = talkDegree[talk.teller] or
                { character:talk.teller, tell:0, listen:0 }
        dialogueLength = talk.dialogue.length
        teller.tell += dialogueLength
        talkDegree[talk.teller] = teller

        for character in talk.listener
          listener = talkDegree[character] or
                    { 'character':character, tell:0, listen:0 }
          listener.listen += dialogueLength
          talkDegree[character] = listener

      $scope.talkDegree = _(talkDegree).values().sortBy('listen').reverse().value()
      $rootScope.allCharacters = _.pluck($scope.talkDegree, "character")

      # Calculate delta(Listen degree)
      $scope.talkDegree[0].delta = 0
      for i in [1 ... $scope.talkDegree.length]
        do (i) ->
          $scope.talkDegree[i].delta = $scope.talkDegree[i-1].listen - $scope.talkDegree[i].listen

      # Character grouping
      avgListenDegree = (_($scope.talkDegree).reduce ((a, d) -> (a + d.listen)), 0) / $scope.talkDegree.length
      avgListenPosition = _.findIndex($scope.talkDegree, (d) -> d.listen <= avgListenDegree)
      maxDeltaPosition = _.findIndex($scope.talkDegree, _.max($scope.talkDegree, 'delta'))

      console.log "avgListenDegree = #{avgListenDegree}"
      console.log "maxDeltaPosition = #{maxDeltaPosition}"
      console.log "avgListenPosition = #{avgListenPosition}"

      $scope.group1Index = 0
      $scope.group2Index = maxDeltaPosition + 1
      $scope.group3Index = avgListenPosition

      # Not working because not generated by Angular ng-repeat
      #$("#talkTable tr:lt(#{group2})").css("color","red")
      #$("#talkTable tr:gt(#{group2}):lt(#{group3})").css("color","green")

      #drawGraph("#clustered_character_net", links, $("#character").width(), $("#character").height())

      ###
      Make Cluster
      ###
      $rootScope.group1 = _.pluck($scope.talkDegree[0...$scope.group2Index], "character")
      $rootScope.group2 = _.pluck($scope.talkDegree[$scope.group2Index...$scope.group3Index], "character")
      $rootScope.group3 = _.pluck($scope.talkDegree[$scope.group3Index...$scope.talkDegree.length], "character")

      console.log "Main Characters:"
      console.log $rootScope.group1
      console.log "Sub Characters:"
      console.log $rootScope.group2
      console.log "Extra Characters:"
      console.log $rootScope.group3

      ###
      Compute Degree Centrality

      Exact algorithm is (Self-edged listen degree + Listen (from other) degree) / ( 2 * Total DC )
      however, every talker is self-listener so t.listen is enough.
      ###

      degree = [0,0,0]
      for t in $scope.talkDegree[0...$scope.group2Index]
        degree[0] += t.listen + t.tell

      for t in $scope.talkDegree[$scope.group2Index...$scope.group3Index]
        degree[1] += t.listen + t.tell

      for t in $scope.talkDegree[$scope.group3Index...$scope.talkDegree.length]
        degree[2] += t.listen + t.tell
      
      DC = _.map degree, (d) -> d / (2 * (degree[0] + degree[1] + degree[2]))

      console.log "Degree Centrality:"
      console.log DC

      $scope.DC = DC

      ###
      Extract group weight
      ###
      console.log "Glinks"
      console.log $rootScope.glinks

      $scope.groupVal = [0,0,0,0,0,0,0,0,0]
      $scope.totalWeight = (_($scope.talkDegree).reduce ((a, d) -> (a + d.listen)), 0)
      console.log "TotalWeight"
      console.log $scope.totalWeight

      $scope.groupVal[0] = $rootScope.glinks[1] # 4) Main -> Sub
      $scope.groupVal[1] = $rootScope.glinks[2] # 5) Main -> Extra
      $scope.groupVal[2] = $rootScope.glinks[6] # 6) Sub -> Main
      $scope.groupVal[3] = $rootScope.glinks[8] # 7) Sub -> Extra
      $scope.groupVal[4] = $rootScope.glinks[3] # 8) Extra -> Main
      $scope.groupVal[5] = $rootScope.glinks[4] # 9) Extra -> Sub
      $scope.groupVal[6] = $rootScope.glinks[0] # 10) Main -> Main
      $scope.groupVal[7] = $rootScope.glinks[7] # 11) Sub -> Sub
      $scope.groupVal[8] = $rootScope.glinks[5] # 12) Extra -> Extra


      ###
      Compute Matrix table with title
      ###
      characters = $rootScope.allCharacters
      $scope.charNetTable = []

      $scope.charNetTable.push(["*"].concat(characters)) # Column Header

      for teller in characters
        row = [teller]
        $scope.charNetTable.push(row)

        for listener in characters
          finder = _.findWhere($rootScope.olinks, {"source":teller, "target":listener})
          row.push(finder?.degree || 0)
