var app = angular.module("audience2");

app.value("serverConfig", { url: "/server/functions.php" });
app.value("analyzerConfig", {
  groups: ['Main', 'Sub', 'Extra']
});