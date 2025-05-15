<?php

require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/header.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/user_weight.php'; 

requireLogin();

$rentalId = isset($_GET['rental_id']) ? (int)$_GET['rental_id'] : 0;


$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.ToolID,
           u.FirstName as RenterFirstName, u.LastName as RenterLastName,
           u.UserID as RenterID
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON r.RenterID = u.UserID
    WHERE r.RentalID = :rentalId
    AND t.OwnerID = :ownerId
    AND r.Status = 'Completed'
");
$stmt->execute([
    'rentalId' => $rentalId,
    'ownerId' => $_SESSION['user_id']
]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    $_SESSION['error_message'] = "Invalid rental or not eligible for review.";
    header('Location: index.php');
    exit();
}

$existingReviewId = null;
$stmt = $pdo->prepare("SELECT ReviewID FROM Review WHERE RentalID = :rentalId AND ReviewerID = :ownerId AND EntityType = 'User' LIMIT 1");
$stmt->execute(['rentalId' => $rentalId, 'ownerId' => $_SESSION['user_id']]);
$existingReviewId = $stmt->fetchColumn();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $rating = (int)$_POST['rating'];
        $comment = sanitizeInput($_POST['comment']);
        $damageReported = isset($_POST['damage_reported']) ? 1 : 0;

        if ($rating < 1 || $rating > 5) {
            throw new Exception("Invalid rating value");
        }

        $pdo->beginTransaction();

        if ($existingReviewId) {
            
            $stmt = $pdo->prepare("
                UPDATE Review
                SET Rating = :rating, Comment = :comment, ReviewDate = NOW()
                WHERE ReviewID = :reviewId
            ");
            if (!$stmt->execute([
                'rating' => $rating,
                'comment' => $comment,
                'reviewId' => $existingReviewId
            ])) {
                throw new Exception("Failed to update review");
            }
            
            $stmtHist = $pdo->prepare("
                UPDATE ReviewHistory
                SET Rating = :rating, ReviewDate = NOW()
                WHERE ReviewID = :reviewId
            ");
            $stmtHist->execute([
                'rating' => $rating,
                'reviewId' => $existingReviewId
            ]);
        } else {
            
            $stmt = $pdo->prepare("
                INSERT INTO Review (
                    ReviewerID, ReviewedEntityID, EntityType,
                    Rating, Comment, ReviewDate, RentalID
                ) VALUES (
                    :reviewerId, :renterId, 'User',
                    :rating, :comment, NOW(), :rentalId
                )
            ");
            if (!$stmt->execute([
                'reviewerId' => $_SESSION['user_id'],
                'renterId' => $rental['RenterID'],
                'rating' => $rating,
                'comment' => $comment,
                'rentalId' => $rentalId
            ])) {
                throw new Exception("Failed to insert review");
            }
            $newReviewId = $pdo->lastInsertId();
            $stmtHist = $pdo->prepare("
                INSERT INTO ReviewHistory (ReviewID, ReviewerID, RevieweeID, Rating, ReviewDate)
                VALUES (:reviewId, :reviewerId, :revieweeId, :rating, NOW())
            ");
            $stmtHist->execute([
                'reviewId' => $newReviewId,
                'reviewerId' => $_SESSION['user_id'],
                'revieweeId' => $rental['RenterID'],
                'rating' => $rating
            ]);
        }

        
        $stmtDamage = $pdo->prepare("UPDATE Rental SET DamageReported = :damageReported WHERE RentalID = :rentalId");
        if (!$stmtDamage->execute(['damageReported' => $damageReported, 'rentalId' => $rentalId])) {
            error_log("Failed to update damage report status for rentalId=$rentalId with damageReported=$damageReported");
            throw new Exception("Failed to update damage report status");
        } else {
            error_log("Damage report status updated successfully for rentalId=$rentalId with damageReported=$damageReported");
        }

        
        error_log("leave_review.php: Calling calculateUserWeight for reviewer weight update - START");
        $weight = calculateUserWeight($pdo, $_SESSION['user_id'], $rental['RenterID'], false, $rentalId, 'reviewer weight update');
        if ($weight === null) {
            error_log("leave_review.php: calculateUserWeight failed for reviewer weight update");
            throw new Exception("Failed to update reviewer weight");
        }
        error_log("leave_review.php: Calling calculateUserWeight for reviewer weight update - END");

        
        $stmtUpdateWeight = $pdo->prepare("UPDATE Reviewweight SET Weight = :weight WHERE UserID = :userId");
        if (!$stmtUpdateWeight->execute(['weight' => $weight, 'userId' => $_SESSION['user_id']])) {
            error_log("Failed to update reviewer weight in Reviewweight table for userId=" . $_SESSION['user_id']);
            throw new Exception("Failed to update reviewer weight in Reviewweight table");
        }

        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM Review WHERE ReviewerID = :reviewerId");
        $stmt->execute(['reviewerId' => $_SESSION['user_id']]);
        $reviewCountGiven = (int)$stmt->fetchColumn();

        
        $stmt = $pdo->prepare("
            UPDATE User
            SET ReviewCount = :review_count
            WHERE UserID = :reviewerId
        ");
        if (!$stmt->execute([
            'review_count' => $reviewCountGiven,
            'reviewerId' => $_SESSION['user_id']
        ])) {
            throw new Exception("Failed to update reviewer review count");
        }

        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM Review WHERE ReviewedEntityID = :revieweeId AND EntityType = 'User'");
        $stmt->execute(['revieweeId' => $rental['RenterID']]);
        $reviewsReceivedCount = (int)$stmt->fetchColumn();

        $stmt = $pdo->prepare("
            UPDATE User
            SET ReviewsReceivedCount = :reviews_received_count
            WHERE UserID = :revieweeId
        ");
        if (!$stmt->execute([
            'reviews_received_count' => $reviewsReceivedCount,
            'revieweeId' => $rental['RenterID']
        ])) {
            throw new Exception("Failed to update reviewee reviews received count");
        }

        $stmt = $pdo->prepare("SELECT AVG(Rating) FROM Review WHERE ReviewerID = :reviewerId AND EntityType = 'User'");
        $stmt->execute(['reviewerId' => $_SESSION['user_id']]);
        $avgRatingGiven = $stmt->fetchColumn();

        $stmt = $pdo->prepare("
            UPDATE User
            SET AvgRatingGiven = :avg_rating_given
            WHERE UserID = :reviewerId
        ");
        if (!$stmt->execute([
            'avg_rating_given' => $avgRatingGiven,
            'reviewerId' => $_SESSION['user_id']
        ])) {
            throw new Exception("Failed to update reviewer average rating given");
        }

        error_log("leave_review.php: Calling calculateNewReputation for reviewed user reputation update - START");
        if (!calculateNewReputation($pdo, $rental['RenterID'], $rentalId, $weight, $rating, true, 'reviewed user reputation update')) {
            error_log("leave_review.php: calculateNewReputation failed for reviewed user reputation update");
            throw new Exception("Failed to update reviewed user reputation score");
        }
        error_log("leave_review.php: Calling calculateNewReputation for reviewed user reputation update - END");

        $pdo->commit();
        $_SESSION['success_message'] = "Review submitted successfully!";
        header('Location: index.php');
        exit();

    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Error submitting review: " . $e->getMessage());
        $error = "Error submitting review: " . htmlspecialchars($e->getMessage());
    }
}

$existingRating = null;
$existingComment = '';
$existingDamageReported = 0;
if ($existingReviewId) {
    $stmt = $pdo->prepare("SELECT Rating, Comment FROM Review WHERE ReviewID = :reviewId");
    $stmt->execute(['reviewId' => $existingReviewId]);
    $reviewData = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($reviewData) {
        $existingRating = (int)$reviewData['Rating'];
        $existingComment = $reviewData['Comment'];
    }
   
    $stmtDamage = $pdo->prepare("SELECT DamageReported FROM Rental WHERE RentalID = :rentalId");
    $stmtDamage->execute(['rentalId' => $rentalId]);
    $existingDamageReported = (int)$stmtDamage->fetchColumn();
}

$currentDate = new DateTime();
$rentalEndDate = new DateTime($rental['RentalEndDate']);
$isPastEndDate = ($currentDate > $rentalEndDate);

include __DIR__ . '/../../assets/html/owner/leave_review.html';

require_once '../../includes/footer.php';
?>