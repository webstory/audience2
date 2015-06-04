angular.module 'audience2', [
  'ngAnimate'
  'ngCookies'
  'ngTouch'
  'ngSanitize'
  'restangular'
  'ui.router'
  'ui.bootstrap'
  'ui.bootstrap.tpls'
  'ui.bootstrap.modal'
  'angular-lodash'
  'ui.codemirror'
  'nvd3'
  'hljs' # Highlightjs
  "checklist-model"
  ]
  .config ($stateProvider, $urlRouterProvider) ->
    $stateProvider
      .state "home",
        url: "/",
        templateUrl: "app/main/main.html",
        controller: "MainCtrl"

    $urlRouterProvider.otherwise '/'

