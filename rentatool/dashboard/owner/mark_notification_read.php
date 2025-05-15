<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['notificationId'])) {
    echo json_encode(['success' => false, 'message' => 'Notification ID missing']);
    exit;
}

$notificationId = intval($data['notificationId']);

try {
    $stmt = $pdo->prepare("UPDATE Notification SET IsRead = 1 WHERE NotificationID = ?");
    $stmt->execute([$notificationId]);
    echo json_encode(['success' => true]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>