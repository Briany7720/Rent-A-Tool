<?php

define('BASE_URL', 'http://localhost/rentatool/');
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'rentatool');


error_reporting(E_ALL);
ini_set('display_errors', 1);

session_start();


function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function getUserType() {
    return isset($_SESSION['user_type']) ? $_SESSION['user_type'] : null;
}

function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: ../auth/login.php');
        exit();
    }
}

function sanitizeInput($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}


function jsonResponse($success, $message, $data = null) {
    if (ob_get_length()) {
        ob_clean();
    }
    header('Content-Type: application/json');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}
?>
