<?php
require_once '../includes/config.php';
require_once '../includes/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = sanitizeInput($_POST['email']);
    $password = $_POST['password'];

    // Check if user exists
    $stmt = $pdo->prepare("SELECT UserID, Password, UserType FROM User WHERE Email = :email");
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user && password_verify($password, $user['Password'])) {
        
        $_SESSION['user_id'] = $user['UserID'];
        $_SESSION['user_type'] = $user['UserType'];
        
        if ($user['UserType'] === 'Owner') {
            header('Location: ../dashboard/owner/index.php');
        } else if ($user['UserType'] === 'Renter') {
            header('Location: ../dashboard/renter/index.php');
        }
        exit();
    } else {
        header('Location: login.php?error=Invalid+email+or+password');
        exit();
    }
}

header('Location: ../assets/html/login.html');
exit();
?>
