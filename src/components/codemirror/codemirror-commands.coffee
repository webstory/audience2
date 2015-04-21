window.CodeMirror.commands.parseScript = (cm) ->
  currentCharacter = 'Noname'
  currentScene = 'Untitled'
  currentDialogue = {}
  characters = new Array()
  dialogues = new Array()

  db = []

  for line in [0..cm.lastLine()]
    ch = 0

    loop
      token = cm.getTokenAt(CodeMirror.Pos(line, ch))
      ch += 1
      break if token.type != null or ch > 80

    try
      if token.type == "sceneheading"
        characters = new Array()
        dialogues = new Array()
        db.push({
          'lineNo': line + 1
          'sceneTitle': token.string.trim()
          'dialogues': dialogues
          'characters': characters
        })

      if token.type == "character"
        currentCharacter = token.string.match(/^\s*([^(]+).*$/)?[1].trim()
        currentDialogue = {}
        currentDialogue.character = currentCharacter || 'Noname'
        currentDialogue.lineNo = line + 1
        currentDialogue.dialogue = ""
        dialogues.push(currentDialogue)
        characters.push(currentCharacter) if $.inArray(currentCharacter, characters) is -1

      if token.type == "dialogue"
        currentDialogue.dialogue += " " + token.string
      if token.type == "paranthetical"
        _.noop() # No operation
    catch error
      console.error "Error at line #{line} : #{error}"

  return db