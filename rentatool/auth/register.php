<?php
require_once '../includes/config.php';
require_once '../includes/db_connection.php';

$error = null;
if (isset($_GET['error'])) {
    $error = htmlspecialchars($_GET['error']);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        
        $firstName = sanitizeInput($_POST['firstName']);
        $lastName = sanitizeInput($_POST['lastName']);
        $email = sanitizeInput($_POST['email']);
        $password = $_POST['password'];
        $confirmPassword = $_POST['confirmPassword'];
        $phoneNumber = sanitizeInput($_POST['phoneNumber']);
        $userType = sanitizeInput($_POST['userType']);

     
        if ($password !== $confirmPassword) {
            
            header('Location: register.php?error=Passwords+do+not+match');
            exit();
        }

        
        $stmt = $pdo->prepare("SELECT UserID FROM User WHERE Email = :email");
        $stmt->execute(['email' => $email]);
        if ($stmt->fetch()) {
            
            header('Location: register.php?error=Email+already+registered');
            exit();
        }

        
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

        
        $stmt = $pdo->prepare("
            INSERT INTO User (FirstName, LastName, PhoneNumber, Email, Password, UserType, ReputationScore)
            VALUES (:firstName, :lastName, :phoneNumber, :email, :password, :userType, 3)
        ");

        $stmt->execute([
            'firstName' => $firstName,
            'lastName' => $lastName,
            'phoneNumber' => $phoneNumber,
            'email' => $email,
            'password' => $hashedPassword,
            'userType' => $userType
        ]);

        
        header('Location: login.php?success=Registration+successful!+Please+login.');
        exit();

    } catch (Exception $e) {
        header('Location: register.php?error=' . urlencode($e->getMessage()));
        exit();
    }
} else {
    // Render the registration form on GET request
    // Read the form HTML and inject error message if any
    $formHtml = file_get_contents('../assets/html/register.html');
    if ($error) {
        // Inject error message div after opening <form> tag
        $formHtml = preg_replace(
            '/(<form[^>]*>)/i',
            '$1' . "\n" . '<div class="bg-red-500 text-white p-3 rounded mb-4">' . $error . '</div>',
            $formHtml,
            1
        );
    }
    echo $formHtml;
}
?>
