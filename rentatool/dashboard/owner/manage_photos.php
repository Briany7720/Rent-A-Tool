<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';
require_once '../../includes/photo_utils.php';

requireLogin();

$toolId = isset($_GET['tool_id']) ? (int)$_GET['tool_id'] : 0;


$stmt = $pdo->prepare("
    SELECT Name
    FROM Tool
    WHERE ToolID = :toolId AND OwnerID = :ownerId
");
$stmt->execute([
    'toolId' => $toolId,
    'ownerId' => $_SESSION['user_id']
]);
$tool = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$tool) {
    $_SESSION['error_message'] = "Invalid tool or unauthorized access.";
    header('Location: tools.php');
    exit();
}


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['action'])) {
            switch ($_POST['action']) {
                case 'upload':
                    if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
                        throw new Exception("No file uploaded or upload error occurred.");
                    }
                    uploadToolPhoto($toolId, $_FILES['photo']);
                    $_SESSION['success_message'] = "Photo uploaded successfully.";
                    break;

                case 'set_primary':
                    $photoId = (int)$_POST['photo_id'];
                    setPrimaryPhoto($toolId, $photoId);
                    $_SESSION['success_message'] = "Primary photo updated.";
                    break;

                case 'delete':
                    $photoId = (int)$_POST['photo_id'];
                    deleteToolPhoto($toolId, $photoId);
                    $_SESSION['success_message'] = "Photo deleted successfully.";
                    break;
            }
        }
    } catch (Exception $e) {
        $_SESSION['error_message'] = $e->getMessage();
    }
    
    
    header("Location: manage_photos.php?tool_id=" . $toolId);
    exit();
}


$photos = getToolPhotos($toolId);


include 'manage_photos.html';

require_once '../../includes/footer.php';
?>