app = angular.module "audience2"

app.factory "analyzerService", ($window, $log, analyzerConfig) ->
  groups = analyzerConfig.groups

  return {
    ###
    Parse Script
    ###
    parseScript: (codemirrorInstance) ->
      parsedScript = $window.CodeMirror.commands["parseScript"](codemirrorInstance)

      return parsedScript

    ###
    Build Character-net
    ###
    buildCharacterNet: (scenes) ->
      links = []

      for scene in scenes
        listeners = scene.characters

        for dialogue in scene.dialogues
          teller = dialogue.character

          for listener in listeners
            # if teller and listener is different character
            # or monologue scene
            if teller != listener or listeners.length == 1
              finder = _.findWhere(links, {"source":teller, "target":listener})

              if finder is undefined or finder is null
                links.push
                  source:teller
                  target:listener
                  degree:dialogue.dialogue.length
              else
                finder.degree += dialogue.dialogue.length

      return links


    ###
    Build Clustered Character-net
    ###
    buildClusteredCharacterNet: (scenes, groupInfo) ->
      main = groupInfo.main.characters
      sub = groupInfo.sub.characters
      extra = groupInfo.extra.characters

      links = []

      for scene in scenes
        listeners = scene.characters

        for dialogue in scene.dialogues
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

      return links

    ###
    Build Talk Matrix
    ###
    buildTalkMatrix: (scenes) ->
      talks = []

      for scene, index in scenes
        sceneNo = index + 1 # Scene number started at 1
        sceneTitle = scene.sceneTitle
        listeners = scene.characters.sort()

        for dialogue in scene.dialogues
          talks.push
            number: sceneNo
            title: sceneTitle
            line: dialogue.lineNo
            teller: dialogue.character
            listener: listeners
            dialogue: dialogue.dialogue

      return talks


    ###
    Build Talk Degree
    ###
    buildTalkDegree: (scenes) ->
      talks = @.buildTalkMatrix(scenes)

      # Character centerality analysis
      # Table structure:
      #   <Character> <Tell-length> <Listen-length> <Delta(Listen)>
      talkDegree = {}

      for talk in talks
        teller = talkDegree[talk.teller] or
                { 'character':talk.teller, tell:0, listen:0 }
        dialogueLength = talk.dialogue.length
        teller.tell += dialogueLength
        talkDegree[talk.teller] = teller

        for character in talk.listener
          listener = talkDegree[character] or
                    { 'character':character, tell:0, listen:0 }
          listener.listen += dialogueLength
          talkDegree[character] = listener

      sortedTD = _(talkDegree).values().sortBy('listen').reverse().value()
      return sortedTD


    ###
    Get All characters
    ###
    getAllCharactersFromTalkDegree: (talkDegree) ->
      _.pluck(talkDegree, "character")

    getAllCharactersFromGroupInfo: (groupInfo) ->
      allCharacters = []
        .concat(groupInfo.main.characters)
        .concat(groupInfo.sub.characters)
        .concat(groupInfo.extra.characters)

      return allCharacters

    ###
    Calculate Delta(Listen degree)
    ###
    buildTalkDegreeDelta: (talkDegree) ->
      sortedTD = _(talkDegree).values().sortBy('listen').reverse().value()

      sortedTD[0].delta = 0
      for i in [1 ... sortedTD.length]
        do (i) ->
          sortedTD[i].delta = sortedTD[i-1].listen - sortedTD[i].listen

      return sortedTD


    ###
    Get Character groups
    ###
    getCharacterGroups: (talkDegree) ->
      if talkDegree[0].delta is undefined
        talkDegree = @.buildTalkDegreeDelta(talkDegree)

      sortedTD = _(talkDegree).values().sortBy('listen').reverse().value()

      groupInfo = {}

      avgListenDegree = (_(sortedTD).reduce ((a, d) -> (a + d.listen)), 0) / sortedTD.length
      avgListenPosition = _.findIndex(sortedTD, (d) -> d.listen <= avgListenDegree)
      maxDeltaPosition = _.findIndex(sortedTD, _.max(sortedTD, 'delta'))

      groupInfo.avgListenDegree = avgListenDegree

      group1Index = 0
      group2Index = maxDeltaPosition + 1
      group3Index = avgListenPosition

      ###
      Make Cluster
      ###
      groupInfo.main =
        index: 0
        characters: _.pluck(sortedTD[0...group2Index], "character")
      groupInfo.sub =
        index: group2Index
        characters: _.pluck(sortedTD[group2Index...group3Index], "character")
      groupInfo.extra =
        index: group3Index
        characters: _.pluck(sortedTD[group3Index...sortedTD.length], "character")

      return groupInfo


    ###
    Compute Degree Centrality

    Exact algorithm is (Self-edged listen degree + Listen (from other) degree) / ( 2 * Total DC )
    however, every talker is self-listener so t.listen is enough.
    ###
    getDegreeCentrality: (talkDegree, groupInfo) ->
      degree = [0,0,0]
      for t in talkDegree[0...groupInfo.sub.index]
        degree[0] += t.listen + t.tell

      for t in talkDegree[groupInfo.sub.index...groupInfo.extra.index]
        degree[1] += t.listen + t.tell

      for t in talkDegree[groupInfo.extra.index...talkDegree.length]
        degree[2] += t.listen + t.tell
      
      DC = _.map degree, (d) -> d / (2 * (degree[0] + degree[1] + degree[2]))

      return DC


    ###
    Build Places
    ###
    getPlaces: (scenes) ->
      # Schema: places {{sceneTitle : [scene#]}}
      # Omit Day/Night
      places = {}

      for s,i in scenes
        title = /^(?:INT\.|EXT\.|INT\/EXT\.)\s*(.+?)\s*-\s*(?:DAY|NIGHT|.+)$/.exec(s.sceneTitle)[1]

        if places[title] != undefined
          places[title].push(i+1)
        else
          places[title] = [i+1]

      return places

  }
