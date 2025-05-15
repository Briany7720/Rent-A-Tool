<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/user_weight.php'; // Use refactored file
require_once '../../includes/header.php';

requireLogin();

$rentalId = isset($_GET['rental_id']) ? (int)$_GET['rental_id'] : 0;

// Fetch rental details for this rental and renter
$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.ToolID,
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName,
           u.UserID as OwnerID
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON t.OwnerID = u.UserID
    WHERE r.RentalID = :rentalId
    AND r.RenterID = :renterId
    AND r.Status = 'Completed'
");
$stmt->execute([
    'rentalId' => $rentalId,
    'renterId' => $_SESSION['user_id']
]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    $_SESSION['error_message'] = "Invalid rental or not eligible for review.";
    header('Location: index.php');
    exit();
}

// Check if a review exists for this rental and reviewer (renter)
$existingReviewId = null;
$stmt = $pdo->prepare("SELECT ReviewID FROM Review WHERE RentalID = :rentalId AND ReviewerID = :renterId AND EntityType = 'User' LIMIT 1");
$stmt->execute(['rentalId' => $rentalId, 'renterId' => $_SESSION['user_id']]);
$existingReviewId = $stmt->fetchColumn();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $rating = (int)$_POST['rating'];
        $comment = sanitizeInput($_POST['comment']);

        if ($rating < 1 || $rating > 5) {
            throw new Exception("Invalid rating value");
        }

        $pdo->beginTransaction();

        if ($existingReviewId) {
            // Update existing review
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
        } else {
            // Insert new review
            $stmt = $pdo->prepare("
                INSERT INTO Review (
                    ReviewerID, ReviewedEntityID, EntityType,
                    Rating, Comment, ReviewDate, RentalID
                ) VALUES (
                    :reviewerId, :ownerId, 'User',
                    :rating, :comment, NOW(), :rentalId
                )
            ");
            if (!$stmt->execute([
                'reviewerId' => $_SESSION['user_id'],
                'ownerId' => $rental['OwnerID'],
                'rating' => $rating,
                'comment' => $comment,
                'rentalId' => $rentalId
            ])) {
                throw new Exception("Failed to insert review");
            }
        }

        // Update User ReviewCount only (ReputationScore updated in calculateUserWeight)
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM Review WHERE ReviewedEntityID = :ownerId AND EntityType = 'User'");
        $stmt->execute(['ownerId' => $rental['OwnerID']]);
        $reviewCount = (int)$stmt->fetchColumn();

        $stmt = $pdo->prepare("
            UPDATE User
            SET ReviewCount = :review_count
            WHERE UserID = :ownerId
        ");
        if (!$stmt->execute([
            'review_count' => $reviewCount,
            'ownerId' => $rental['OwnerID']
        ])) {
            throw new Exception("Failed to update user review count");
        }

        // Use PHP function to calculate user weight and update reputation score for owner (reviewed user)
        $weight = calculateUserWeight($pdo, $_SESSION['user_id'], $rental['OwnerID'], true, $rentalId, 'reviewed user reputation update');
        if ($weight === null) {
            throw new Exception("Failed to update owner reputation score");
        }

        // Add call to update renter weight as reviewer with reviewedUserId = ownerId and isOwnerReview = false
        $weightReviewer = calculateUserWeight($pdo, $_SESSION['user_id'], $rental['OwnerID'], false, $rentalId, 'reviewer weight update');
        if ($weightReviewer === null) {
            throw new Exception("Failed to update renter weight");
        }

        // Recalculate ReviewCount for reviewer (renter)
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

        // Update ReviewsReceivedCount for renter (reviewee) using the value directly from the database after all calculations and reputation update
        $stmt = $pdo->prepare("SELECT ReviewsReceivedCount FROM User WHERE UserID = :revieweeId");
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
            throw new Exception("Failed to update renter reviews received count");
        }

        // Recalculate AvgRatingGiven for reviewer (renter)
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

        $pdo->commit();
        $_SESSION['success_message'] = "Review submitted successfully!";
        header('Location: index.php');
        exit();

    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Review submission error: " . $e->getMessage());
        $error = "Error submitting review: " . htmlspecialchars($e->getMessage());
    }
}

// Fetch existing review data to pre-fill form if exists
$existingRating = null;
$existingComment = '';
if ($existingReviewId) {
    $stmt = $pdo->prepare("SELECT Rating, Comment FROM Review WHERE ReviewID = :reviewId");
    $stmt->execute(['reviewId' => $existingReviewId]);
    $reviewData = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($reviewData) {
        $existingRating = (int)$reviewData['Rating'];
        $existingComment = $reviewData['Comment'];
    }
}


include __DIR__ . '/../../assets/html/renter/leave_review.html';

?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('toolName').textContent = '<?php echo htmlspecialchars($rental['ToolName']); ?>';
        document.getElementById('ownerName').textContent = '<?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>';
        document.getElementById('rentalDates').textContent = '<?php 
            echo date('M d, Y', strtotime($rental['RentalStartDate'])) . ' - ' . 
            date('M d, Y', strtotime($rental['RentalEndDate'])); 
        ?>';
        
        
        <?php if (isset($error)): ?>
        const errorMsg = document.getElementById('error-message');
        errorMsg.style.display = 'block';
        document.getElementById('error-text').textContent = '<?php echo addslashes($error); ?>';
        <?php endif; ?>

        
        <?php if ($existingReviewId): ?>
        document.getElementById('review-exists-message').style.display = 'block';
        document.getElementById('review-form').style.display = 'none';
        <?php else: ?>
        
        <?php if ($existingRating): ?>
        document.querySelector('input[name="rating"][value="<?php echo $existingRating; ?>"]').checked = true;
        document.querySelector('textarea[name="comment"]').value = '<?php echo addslashes($existingComment); ?>';
        <?php endif; ?>
        <?php endif; ?>
    });
</script>

<?php require_once '../../includes/footer.php'; ?>