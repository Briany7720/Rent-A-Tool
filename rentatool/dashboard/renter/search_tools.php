<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';

$tools = [];


if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['search'])) {
    $search = sanitizeInput($_GET['search']);
    $category = isset($_GET['category']) ? sanitizeInput($_GET['category']) : '';
    $location = isset($_GET['location']) ? sanitizeInput($_GET['location']) : '';
    $delivery = isset($_GET['delivery']) ? sanitizeInput($_GET['delivery']) : '';

    $params = ['search' => '%' . $search . '%'];
    $query = "SELECT DISTINCT t.ToolID, t.Name, t.Category, t.PricePerDay, t.OwnerID, t.Location, t.DeliveryOption, u.FirstName, u.LastName
              FROM Tool t
              JOIN User u ON t.OwnerID = u.UserID
              WHERE (t.Name LIKE :search OR u.FirstName LIKE :search OR u.LastName LIKE :search)";
    
    if ($category) {
        $query .= " AND t.Category = :category";
        $params['category'] = $category;
    }
    if ($location) {
        $query .= " AND REPLACE(LOWER(t.Location), ' ', '') LIKE REPLACE(LOWER(:location), ' ', '')";
        $params['location'] = '%' . str_replace(' ', '', strtolower($location)) . '%';
    }
    if ($delivery) {
        if ($delivery === 'Both') {
            $query .= " AND t.DeliveryOption IN ('Pickup Only', 'Delivery Available')";
        } else {
            $query .= " AND t.DeliveryOption = :delivery";
            $params['delivery'] = $delivery;
        }
    }
    
    $query .= " AND t.AvailabilityStatus = 'Available'";

    
    error_log("Query: $query");
    error_log("Params: " . print_r($params, true));

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $tools = $stmt->fetchAll(PDO::FETCH_ASSOC);

    error_log("Tools fetched: " . print_r($tools, true));

    $uniqueTools = [];
    $seenToolIDs = [];
    foreach ($tools as $tool) {
        if (!in_array($tool['ToolID'], $seenToolIDs)) {
            $seenToolIDs[] = $tool['ToolID'];
            $uniqueTools[] = $tool;
        }
    }
    $tools = $uniqueTools;

    
    error_log("Tools after deduplication: " . print_r($tools, true));

    
    foreach ($tools as &$tool) {
        $stmtPhoto = $pdo->prepare("SELECT PhotoPath FROM ToolPhoto WHERE ToolID = :toolID LIMIT 1");
        $stmtPhoto->execute(['toolID' => $tool['ToolID']]);
        $photo = $stmtPhoto->fetch(PDO::FETCH_ASSOC);
        $tool['PhotoPath'] = $photo ? $photo['PhotoPath'] : null;
    }

    error_log("Tools after fetching photos: " . print_r($tools, true));
}


include __DIR__ . '/../../assets/html/renter/search_tools.html';

?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
       
        <?php if (isset($_GET['search'])): ?>
        document.getElementById('searchInput').value = '<?php echo htmlspecialchars($_GET['search']); ?>';
        <?php endif; ?>
        
        <?php if (isset($_GET['category'])): ?>
        document.getElementById('categorySelect').value = '<?php echo htmlspecialchars($_GET['category']); ?>';
        <?php endif; ?>
        
        <?php if (isset($_GET['location'])): ?>
        document.getElementById('locationInput').value = '<?php echo htmlspecialchars($_GET['location']); ?>';
        <?php endif; ?>
        
        <?php if (isset($_GET['delivery'])): ?>
        document.getElementById('deliverySelect').value = '<?php echo htmlspecialchars($_GET['delivery']); ?>';
        <?php endif; ?>
        
      
        <?php if (empty($tools)): ?>
        document.getElementById('no-tools-message').style.display = 'block';
        document.getElementById('tools-container').style.display = 'none';
        <?php else: ?>
        const toolsContainer = document.getElementById('tools-container');
        console.log("Tools to render:", <?php echo json_encode($tools); ?>);

        <?php foreach ($tools as $tool): ?>
        const toolCard = document.createElement('div');
        toolCard.className = 'bg-white rounded-lg shadow p-4 flex flex-col';
        
        
        <?php if ($tool['PhotoPath']): ?>
        toolCard.innerHTML += `
            <img src="<?php echo htmlspecialchars(BASE_URL . $tool['PhotoPath']); ?>" alt="Tool Image" class="h-48 w-full object-cover rounded mb-4">
        `;
        <?php else: ?>
        toolCard.innerHTML += `
            <div class="h-48 w-full bg-gray-200 rounded mb-4 flex items-center justify-center text-gray-500">
                No Image
            </div>
        `;
        <?php endif; ?>
        
        
        toolCard.innerHTML += `
            <h3 class="text-lg font-semibold mb-1"><?php echo htmlspecialchars($tool['Name']); ?></h3>
            <p class="text-sm text-gray-600 mb-1">Owner: <a href="<?php echo BASE_URL; ?>dashboard/shared/user_profile.php?user_id=<?php echo $tool['OwnerID']; ?>" class="text-blue-600 hover:underline"><?php echo htmlspecialchars($tool['FirstName'] . ' ' . $tool['LastName']); ?></a></p>
            <p class="text-sm text-gray-600 mb-1">Category: <?php echo htmlspecialchars($tool['Category']); ?></p>
            <p class="text-sm text-gray-600 mb-1">Location: <?php echo htmlspecialchars($tool['Location'] ?? ''); ?></p>
            <p class="text-sm text-gray-600 mb-1">Delivery Option: <?php echo htmlspecialchars($tool['DeliveryOption'] ?? ''); ?></p>
            <p class="text-sm font-medium mb-4">$<?php echo number_format($tool['PricePerDay'], 2); ?> per day</p>
            <a href="rent_tool.php?tool_id=<?php echo $tool['ToolID']; ?>" class="mt-auto bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 text-center">
                Rent
            </a>
        `;
        
        console.log("Appending tool card:", toolCard);
        toolsContainer.appendChild(toolCard);
        <?php endforeach; ?>
        <?php endif; ?>
    });
</script>

<?php require_once '../../includes/footer.php'; ?>