app = angular.module "audience2"

###
Load Doc Dialogue controller
###
app.controller "loadDocCtrl", ($scope, $modalInstance, items) ->
  $scope.items = items
  $scope.selected =
    item: $scope.items[0]

  $scope.ok = ->
    $modalInstance.close($scope.selected.item)

  $scope.cancel = ->
    $modalInstance.dismiss('cancel')



###
Share Doc Dialogue controller
###
app.controller "shareDocCtrl", ($scope, $http, $log, $modalInstance, title, items, documentDbService) ->
  $scope.title = title
  $scope.items = items
  $scope.selected =
    item: $scope.items[0]

  $scope.invite = ->
    user = prompt "Invite User", ""

    if user?
      documentDbService.addShare(user, title).success (data) ->
        $log.debug data?.status || data
        $scope.items.push({"user":user})

  $scope.remove = (index) ->
    user = $scope.items[index].user
    documentDbService.removeShare(user, title).success (data) ->
      console.log data?.status || data
      $scope.items.splice(index, 1)

  $scope.ok = -> $modalInstance.close('ok')
  $scope.cancel = -> $modalInstance.dismiss('cancel')


###
Document Manager controller
###
app.controller "documentManagerCtrl", ($scope, $modal, $log, documentDbService) ->
  setEditorContent = (newTitle, newContent) ->
    $scope.$parent.editorTitle = newTitle
    $scope.$parent.editor = newContent

  $scope.newDoc = ->
    newTitle = prompt "Enter new Filename", $scope.$parent.editorTitle
    if newTitle?
      documentDbService.newDoc(newTitle).success (data) ->
        setEditorContent(data.title, data.document)
        if data.code != 0 then alert data.status

  $scope.loadDoc = ->
    documentDbService.listDoc().success (data) ->
      file_choose = $modal.open
        templateUrl: "components/templates/filelist.tmpl.html"
        controller: 'loadDocCtrl'
        size: 'lg'
        resolve:
          items: -> data

      file_choose.result.then (selectedItem) ->
        documentDbService.loadDoc(selectedItem)
        .success (data) ->
          $log.info "Document '#{data.title}' is loaded. filesize: #{data.document.length}"
          setEditorContent(data.title, data.document)
        .error (data) ->
          $log.error data

  $scope.saveDoc = (canOverwrite = true) ->
    documentDbService.saveDoc($scope.$parent.editorTitle, $scope.$parent.editor, canOverwrite).success (data) ->
      alert(data?.status || data)

  $scope.saveDocAs = ->
    newTitle = prompt "Enter new Filename", $scope.$parent.editorTitle
    if newTitle?
      $scope.$parent.editorTitle = newTitle
      $scope.saveDoc(false)

  $scope.deleteDoc = ->
    sure = prompt "To DELETE this document, Enter this title below", ""

    if sure == $scope.$parent.editorTitle
      documentDbService.deleteDoc($scope.$parent.editorTitle).success (data) ->
        alert(data?.status || data)
        # TODO: Replace better reload
        location.reload()

  $scope.shareDoc = ->
    documentDbService.listShare($scope.$parent.editorTitle).success (data) ->
      if data.length == 0
        alert "Owner can only perform this action."
        return # Cancel action

      modalResult = $modal.open
        templateUrl: "components/templates/sharelist.tmpl.html"
        controller: 'shareDocCtrl'
        size: 'sm'
        resolve:
          title: -> $scope.$parent.editorTitle
          items: -> data
