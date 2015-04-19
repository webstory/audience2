app = angular.module "audience2"

app.factory "documentDbService", ($http, serverConfig) ->
  newDoc: (title) ->
    $http.get(serverConfig.url, {params:{"method":"new", "filename":title}, cache:false})

  listDoc: ->
    $http.get(serverConfig.url, {params:{"method":"list"}, cache:false})

  loadDoc: (filename) ->
    $http.get(serverConfig.url, {params:{"method":"load", "filename":filename}, cache:false})

  saveDoc: (title, content, canOverwrite) ->
    $http
      method: 'POST'
      url: serverConfig.url
      data: {"content": content}
      params: {"method":"save", "filename":title, "overwrite":canOverwrite}

  deleteDoc: (title) ->
    $http.get(serverConfig.url, {params:{"method":"delete", "filename":title}, cache:false})

  listShare: (title) ->
    $http.get(serverConfig.url, {params:{"method":"listShare", "filename":title}, cache:false})

  addShare: (user, title) ->
    $http.get(serverConfig.url, {params:{"method":"addShare", "user":user, "filename":title}})

  removeShare: (user, title) ->
    $http.get(serverConfig.url, {params:{"method":"removeShare", "user":user, "filename":title}})
