<?php
session_start();
header("Access-Control-Allow-Origin: *");

$user_id = null;
$user_name = null;

if(isset($_SESSION['user_id']) && isset($_SESSION['user_name'])) {
  $user_id = $_SESSION['user_id'];
  $user_name = $_SESSION['user_name'];
}

$payload = null;
if(isset($HTTP_RAW_POST_DATA)) {
  $payload = json_decode($HTTP_RAW_POST_DATA, true);
}

/* DB common */
require_once("dbinfo.php");

$con = new mysqli($db_host, $db_user, $db_pw, $db_name);

if($con->connect_errno) {
  die("Failed to connect to MySQL: (" . $con->connect_errno . ") " . $con->connect_error);
}

$method = "unknown";
if(isset($_GET['method'])) {
  $method = $_GET['method'];  
}

$filename = null;
if(isset($_GET['filename'])) {
  $filename = $_GET['filename'];
}

// switch behavior
switch($method) {
  case 'login':
    echo login();
  break;

  case 'logout':
    echo logout();
  break;

  case 'new':
    login_required();
    echo newDoc($filename);
  break;

  case 'list':
    login_required();
    echo listDoc();
  break;

  case 'load':
    login_required();
    echo loadDoc($filename);
  break;

  case 'save':
    login_required();
    echo saveDoc($filename, $payload['content'], $_GET['overwrite']);
  break;

  case 'delete':
    login_required();
    echo deleteDoc($filename);
  break;


  case 'listShare':
    login_required();
    echo listShare($filename);
  break;

  case 'addShare':
    login_required();
    echo addShare($_GET['user'], $filename);
  break;

  case 'removeShare':
    login_required();
    echo removeShare($_GET['user'], $filename);
  break;


  default:
    echo 'Error: Unknown method: '.$method;
  break;
}

/* Clean up */
$con->close();
exit;

/* Authentication */
function login_required() {
  global $con;

  if(!isset($_SESSION['user_id']) || !isset($_SESSION['user_name'])) {
    http_response_code(401);
    $con->close();
    die();
  }
}

function login() {
  global $con, $payload;

  logout();
  session_start();

  $user_id = $payload['id'];
  $password = $payload['pw'];

  $stmt1 = $con->prepare("SELECT user_name, description from user where user_id=? and user_pw=? limit 1;");
  $stmt1->bind_param("ss", $user_id, $password);

  $stmt1->execute();

  $user_name = null;
  $user_description = null;
  $stmt1->bind_result($user_name, $description);

  $user = $stmt1->fetch();

  // Check if denied
  if(!$user) {
    $stmt1->close();
    http_response_code(403);
    return json_encode(array("status"=>"deny", "message"=>$user_id."@".$password));
  }

  $stmt1->close();

  $_SESSION['user_id'] = $user_id;
  $_SESSION['user_name'] = $user_name;

  // Accepted(Use php session)
  $session_key = session_id();

  return json_encode(array("status"=>"accept", "message"=>array("session_key"=>$session_key, "user_name"=>$user_name)));
}

function logout() {
  session_destroy();
  return json_encode(array("status"=>"logout", "code"=>0));
}

/* New Script */
function newDoc($filename) {
  global $con, $user_id;

  $stmt = $con->prepare("SELECT user_id FROM document WHERE title=? LIMIT 1");
  $stmt->bind_param("s", $filename);

  $stmt->execute();

  $owner = NULL;
  $stmt->bind_result($owner);

  $alreadyExists = $stmt->fetch();
  $stmt->close();

  if($alreadyExists) {
    return json_encode(array("status"=>"This title: <$filename> already occupied by <$owner>.", "code"=>-2));
  }

  $saveDocStatus = json_decode(saveDoc($filename, "", false), true);
  $loadDocStatus = json_decode(loadDoc($filename), true);
  return json_encode(array_merge($loadDocStatus, $saveDocStatus));
}

/* Save Script */
function saveDoc($filename, $content, $overwrite) {
  global $con, $user_id;

  /* Check Permission & extrace document owner */
  $stmt = $con->prepare("SELECT A.user_id as owner FROM document as A INNER JOIN acl as B ON A.title=B.document_title WHERE B.user_id=? AND A.title=? LIMIT 1");
  $stmt->bind_param("ss", $user_id, $filename);

  $stmt->execute();

  $owner = NULL;
  $stmt->bind_result($owner);
  $exists = $stmt->fetch();
  $stmt->close();

  if($exists) {
    if($overwrite == false || $overwrite == "false") {
      return json_encode(array("status"=>"Error: File already exists!", "code"=>-1));
    }
    $now = time();
    $stmt = $con->prepare("UPDATE document SET document=?,mdate=NOW() WHERE title=? AND user_id=?");
    $stmt->bind_param("sss", $content, $filename, $owner);

    $stmt->execute();

    return json_encode(array("status"=>"".date("D M j G:i:s T Y", $now)." Saved.", "code"=>0));
  } else {
    $stmt1 = $con->prepare("INSERT INTO document(title,document,user_id) VALUES (?,?,?)");
    $stmt1->bind_param("sss", $filename, $content, $user_id);

    $stmt1->execute();
    $stmt1->close();

    $stmt2 = $con->prepare("INSERT INTO acl(document_title,user_id,permission) VALUES (?,?,?)");
    $defaultPerm = 666;
    $stmt2->bind_param("ssi", $filename, $user_id, $defaultPerm);

    $stmt2->execute();
    $stmt2->close();

    return json_encode(array("status"=>"Saved.", "code"=>0));
  }

}

/* List Script */
function listDoc() {
  global $con, $user_id;

  $stmt = $con->prepare("SELECT A.title, A.user_id, A.mdate FROM document as A INNER JOIN acl as B ON A.title=B.document_title WHERE B.user_id=? ORDER BY mdate DESC");
  $stmt->bind_param("s", $user_id);

  $stmt->execute();

  $title = NULL;
  $owner = NULL;
  $mdate = NULL;
  $titlelist = array();
  $stmt->bind_result($title, $owner, $mdate);

  while($stmt->fetch()) {
    array_push($titlelist, array("owner"=>$owner, "title"=>$title, "mdate"=>$mdate));
  }
  $stmt->close();

  return json_encode($titlelist);
}

/* Load Script */
function loadDoc($filename) {
  global $con, $user_id;

  $stmt = $con->prepare("SELECT A.document FROM document as A INNER JOIN acl as B ON A.title=B.document_title WHERE B.user_id=? AND A.title=? LIMIT 1");
  $stmt->bind_param("ss", $user_id, $filename);

  $stmt->execute();

  $document = NULL;
  $stmt->bind_result($document);
  $stmt->fetch();
  $stmt->close();

  return json_encode(array("title"=>$filename,"document"=>$document));
}

/* Delete Script */
function deleteDoc($filename) {
  global $con, $user_id;

  // Permission check
  $stmt = $con->prepare("SELECT A.user_id as owner FROM document as A INNER JOIN acl as B ON A.title=B.document_title WHERE B.user_id=? AND A.title=? LIMIT 1");
  $stmt->bind_param("ss", $user_id, $filename);

  $stmt->execute();

  $owner = NULL;
  $stmt->bind_result($owner);
  $exists = $stmt->fetch();
  $stmt->close();

  if(!$exists || $owner != $user_id) { // Not owner
    return json_encode(array("status"=>"You are not the owner!", "code"=>-100));
  }

  // Delete document
  $stmt1 = $con->prepare("DELETE FROM document WHERE user_id=? AND title=? LIMIT 1");
  $stmt1->bind_param("ss", $user_id, $filename);

  $stmt1->execute();
  $stmt1->close();

  $stmt2 = $con->prepare("DELETE FROM acl WHERE document_title=?");
  $stmt2->bind_param("s", $filename);

  $stmt2->execute();
  $stmt2->close();

  return json_encode(array("status"=>"Deleted.", "code"=>0));
}

/* ACL functions */

/* List share list(owner only) */
function listShare($filename) {
  global $con, $user_id;

  $stmt = $con->prepare("SELECT user_id FROM acl WHERE document_title=? ORDER BY idx");
  $stmt->bind_param("s", $filename);

  $stmt->execute();

  $user = NULL;
  $sharelist = array();
  $stmt->bind_result($user);

  while($stmt->fetch()) {
    array_push($sharelist, array("user"=>$user));
  }
  $stmt->close();

  if($sharelist[0]['user'] != $user_id) { // Not the owner
    return json_encode(array());
  }

  return json_encode($sharelist);
}

/* Add share(owner only) */
function addShare($share_user_id, $filename) {
  global $con, $user_id;

  $isOwner = count(json_decode(listShare($filename), true)) > 0;

  if(!$isOwner) {
    return json_encode(array("status"=>"You are not the owner!", "code"=>-100));
  }

  $stmt = $con->prepare("INSERT INTO acl(document_title,user_id,permission) VALUES (?,?,?)");
  $defaultPerm = 666;
  $stmt->bind_param("ssi", $filename, $share_user_id, $defaultPerm);

  $stmt->execute();
  $stmt->close();

  return json_encode(array("status"=>"Added.", "code"=>0));
}

/* Remove share(owner only) */
function removeShare($share_user_id, $filename) {
  global $con, $user_id;

  $isOwner = count(json_decode(listShare($filename), true)) > 0;

  if(!$isOwner) {
    return json_encode(array("status"=>"You are not the owner!", "code"=>-100));
  }

  if($user_id == $share_user_id && $isOwner) { // Try to remove owner
    return json_encode(array("status"=>"Owner cannot remove from share!", "code"=>-101));
  }

  $stmt = $con->prepare("DELETE FROM acl WHERE document_title=? AND user_id=?");
  $stmt->bind_param("ss", $filename, $share_user_id);

  $stmt->execute();
  $stmt->close();

  return json_encode(array("status"=>"Removed.", "code"=>0));
}

?>