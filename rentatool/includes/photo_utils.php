<?php
function uploadToolPhoto($toolId, $photoFile) {
    global $pdo;
    
    
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    $maxSize = 5 * 1024 * 1024; // 5MB
    
    if (!in_array($photoFile['type'], $allowedTypes)) {
        throw new Exception("Invalid file type. Only JPG, PNG and GIF are allowed.");
    }
    
    if ($photoFile['size'] > $maxSize) {
        throw new Exception("File is too large. Maximum size is 5MB.");
    }
    
    $extension = pathinfo($photoFile['name'], PATHINFO_EXTENSION);
    $filename = uniqid("tool_{$toolId}_") . '.' . $extension;
    $uploadPath = __DIR__ . '/../uploads/tools/' . $filename;
    
    if (!move_uploaded_file($photoFile['tmp_name'], $uploadPath)) {
        throw new Exception("Failed to upload file.");
    }
    
    $stmt = $pdo->prepare("
        INSERT INTO ToolPhoto (ToolID, PhotoPath) 
        VALUES (:toolId, :photoPath)
    ");
    
    $stmt->execute([
        'toolId' => $toolId,
        'photoPath' => 'uploads/tools/' . $filename
    ]);
    
    $photoId = $pdo->lastInsertId();
    
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as photo_count 
        FROM ToolPhoto 
        WHERE ToolID = :toolId
    ");
    $stmt->execute(['toolId' => $toolId]);
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['photo_count'];
    
    if ($count == 1) {
        $stmt = $pdo->prepare("CALL SetPrimaryPhoto(:toolId, :photoId)");
        $stmt->execute([
            'toolId' => $toolId,
            'photoId' => $photoId
        ]);
    }
    
    return $photoId;
}

function getToolPhotos($toolId) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT PhotoID, PhotoPath, IsPrimary, UploadedAt
        FROM ToolPhoto
        WHERE ToolID = :toolId
        ORDER BY IsPrimary DESC, UploadedAt DESC
    ");
    
    $stmt->execute(['toolId' => $toolId]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function setPrimaryPhoto($toolId, $photoId) {
    global $pdo;
    
    
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as photo_exists
        FROM ToolPhoto
        WHERE PhotoID = :photoId AND ToolID = :toolId
    ");
    $stmt->execute([
        'photoId' => $photoId,
        'toolId' => $toolId
    ]);
    
    if ($stmt->fetch(PDO::FETCH_ASSOC)['photo_exists'] == 0) {
        throw new Exception("Invalid photo ID.");
    }
    
    $stmt = $pdo->prepare("CALL SetPrimaryPhoto(:toolId, :photoId)");
    $stmt->execute([
        'toolId' => $toolId,
        'photoId' => $photoId
    ]);
}

function deleteToolPhoto($toolId, $photoId) {
    global $pdo;
    
    
    $stmt = $pdo->prepare("
        SELECT PhotoPath, IsPrimary
        FROM ToolPhoto
        WHERE PhotoID = :photoId AND ToolID = :toolId
    ");
    $stmt->execute([
        'photoId' => $photoId,
        'toolId' => $toolId
    ]);
    $photo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$photo) {
        throw new Exception("Invalid photo ID.");
    }
    
  
    $pdo->beginTransaction();
    
    try {
        $stmt = $pdo->prepare("
            DELETE FROM ToolPhoto
            WHERE PhotoID = :photoId AND ToolID = :toolId
        ");
        $stmt->execute([
            'photoId' => $photoId,
            'toolId' => $toolId
        ]);
 
        if ($photo['IsPrimary']) {
            $stmt = $pdo->prepare("
                SELECT PhotoID
                FROM ToolPhoto
                WHERE ToolID = :toolId
                ORDER BY UploadedAt DESC
                LIMIT 1
            ");
            $stmt->execute(['toolId' => $toolId]);
            $newPrimary = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($newPrimary) {
                $stmt = $pdo->prepare("CALL SetPrimaryPhoto(:toolId, :photoId)");
                $stmt->execute([
                    'toolId' => $toolId,
                    'photoId' => $newPrimary['PhotoID']
                ]);
            }
        }
        
        $pdo->commit();
        
        $filePath = __DIR__ . '/../' . $photo['PhotoPath'];
        if (file_exists($filePath)) {
            unlink($filePath);
        }
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
}

function getToolPrimaryPhoto($toolId) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT PhotoPath
        FROM ToolPhoto
        WHERE ToolID = :toolId AND IsPrimary = TRUE
        LIMIT 1
    ");
    
    $stmt->execute(['toolId' => $toolId]);
    $photo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    return $photo ? $photo['PhotoPath'] : null;
}
?>
