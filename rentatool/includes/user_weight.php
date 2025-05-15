<?php
function calculateUserWeight(PDO $pdo, int $reviewerId, int $reviewedUserId, bool $isOwnerReview, int $rentalId, string $context = ''): ?float {
    try {
        
        $stmt = $pdo->prepare("SELECT DATEDIFF(CURDATE(), RegistrationDate) AS tenureDays, ReputationScore, ReviewCount, AvgRatingGiven FROM User WHERE UserID = :userId");
        $stmt->execute(['userId' => $reviewerId]);
        $reviewerData = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$reviewerData) {
            error_log("calculateUserWeight [$context]: Reviewer user not found. reviewerId=$reviewerId, reviewedUserId=$reviewedUserId");
            return null;
        }
        $tenureDays = (int)$reviewerData['tenureDays'];
        $reputationScore = (float)$reviewerData['ReputationScore'];
        $reviewCount = (int)$reviewerData['ReviewCount'];
        $avgRatingGiven = (float)$reviewerData['AvgRatingGiven'];

        
        $stmt = $pdo->prepare("SELECT Rating FROM Review WHERE ReviewerID = :reviewerId AND ReviewedEntityID = :reviewedUserId AND RentalID = :rentalId ORDER BY ReviewDate DESC LIMIT 1");
        $stmt->execute(['reviewerId' => $reviewerId, 'reviewedUserId' => $reviewedUserId, 'rentalId' => $rentalId]);
        $ratingGivenRaw = $stmt->fetchColumn();
        if ($ratingGivenRaw === false) {
            error_log("calculateUserWeight [$context]: No rating found for reviewerId=$reviewerId, reviewedUserId=$reviewedUserId, rentalId=$rentalId");
            return null; 
        }
        $ratingGiven = (float)$ratingGivenRaw;
        error_log("calculateUserWeight [$context]: Fetched ratingGiven=$ratingGiven for reviewerId=$reviewerId, reviewedUserId=$reviewedUserId, rentalId=$rentalId");

       
        if ($ratingGiven < $avgRatingGiven) {
            $rawMultiplier = 1 + abs($avgRatingGiven - $ratingGiven);
            $reputationBiasMultiplier = min($rawMultiplier, 3);
            if ($rawMultiplier > 3) {
                error_log("calculateUserWeight: Reputation bias multiplier capped at 3x for reviewerId=$reviewerId, ratingGiven=$ratingGiven, avgRatingGiven=$avgRatingGiven");
            }
        } else {
            $reputationBiasMultiplier = 1;
            error_log("calculateUserWeight: No reputation bias boost for positive deviation for reviewerId=$reviewerId, ratingGiven=$ratingGiven, avgRatingGiven=$avgRatingGiven");
        }

       
        $weight = log10($tenureDays + 1) * ($reputationScore / 5) * log10($reviewCount + 1) * $reputationBiasMultiplier;

        
        error_log("calculateUserWeight Debug: tenureDays=$tenureDays, reputationScore=$reputationScore, reviewCount=$reviewCount, avgRatingGiven=$avgRatingGiven, ratingGiven=$ratingGiven, reputationBiasMultiplier=$reputationBiasMultiplier, calculated weight=$weight");

        return $weight;
    } catch (Exception $e) {
        error_log("Error in calculateUserWeight: " . $e->getMessage());
        return null;
    }
}

function calculateNewReputation($pdo, $reviewedUserId, $rentalId, $weight, $ratingGiven, $isOwnerReview = false, $context = '') {
    
    $stmt = $pdo->prepare("SELECT ReviewsReceivedCount, ReputationScore FROM User WHERE UserID = :userId");
    $stmt->execute(['userId' => $reviewedUserId]);
    $userData = $stmt->fetch(PDO::FETCH_ASSOC);

    $existingReviewsCount = $userData ? (int)$userData['ReviewsReceivedCount'] : 0;
    $currentReputationScore = $userData ? (float)$userData['ReputationScore'] : 0.0;

    
    $behaviorFactor = 1.0;

    
    $stmt = $pdo->prepare("SELECT DamageReported, RentalEndDate FROM Rental WHERE RentalID = :rentalId");
    $stmt->execute(['rentalId' => $rentalId]);
    $rentalData = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($rentalData) {
        $damageReported = (int)$rentalData['DamageReported'];
        $rentalEndDate = new DateTime($rentalData['RentalEndDate']);
        $currentDate = new DateTime();

        
        $notReturned = false;
        if (isset($_POST['not_returned']) && $_POST['not_returned'] == '1') {
            $notReturned = true;
        }

        if ($notReturned) {
            $behaviorFactor = 0.25;
        } elseif ($damageReported) {
            $behaviorFactor = 0.5;
        } elseif ($currentDate > $rentalEndDate) {
            $behaviorFactor = 0.75;
        } else {
            $behaviorFactor = 1.0;
        }
    }

    error_log("calculateNewReputation: Behavior factor $behaviorFactor applied for rentalId=$rentalId");

    
    $adjustedRatingGiven = $ratingGiven * $behaviorFactor;

    
    error_log("calculateNewReputation: currentReputationScore = $currentReputationScore");
    error_log("calculateNewReputation: existingReviewsCount = $existingReviewsCount");
    error_log("calculateNewReputation: ratingGiven = $ratingGiven");
    error_log("calculateNewReputation: behaviorFactor = $behaviorFactor");
    error_log("calculateNewReputation: adjustedRatingGiven = $adjustedRatingGiven");
    error_log("calculateNewReputation: weight = $weight");

    
    $numerator = ($currentReputationScore * $existingReviewsCount) + ($adjustedRatingGiven * $weight);
    $denominator = $existingReviewsCount + $weight;

    error_log("calculateNewReputation: Numerator value = $numerator");
    error_log("calculateNewReputation: Denominator value = $denominator");

    if ($denominator > 0) {
        $newReputationScore = $numerator / $denominator;
        error_log("calculateNewReputation: Calculated newReputationScore=$newReputationScore for reviewedUserId=$reviewedUserId");
        $stmt = $pdo->prepare("UPDATE User SET ReputationScore = :newReputationScore WHERE UserID = :userId");
        $stmt->execute(['newReputationScore' => $newReputationScore, 'userId' => $reviewedUserId]);
    } else {
        $newReputationScore = $ratingGiven; 
        error_log("calculateNewReputation: Denominator zero or negative, using ratingGiven as newReputationScore for reviewedUserId=$reviewedUserId");
        $stmt = $pdo->prepare("UPDATE User SET ReputationScore = :newReputationScore WHERE UserID = :userId");
        $stmt->execute(['newReputationScore' => $newReputationScore, 'userId' => $reviewedUserId]);
    }

    return true;
}
?>
