
const toolPhotosMap = window.toolPhotosMap || {};
const toolRentals = window.toolRentals || {};


function showAddToolModal() {
    document.getElementById('addToolModal').classList.remove('hidden');
}


function hideAddToolModal() {
    document.getElementById('addToolModal').classList.add('hidden');
}


function showEditToolModal(tool) {
    if (typeof tool === 'string') {
        try {
            tool = JSON.parse(tool);
        } catch (e) {
            console.error('Failed to parse tool JSON:', e);
            return;
        }
    }
    document.getElementById('editToolID').value = tool.ToolID;
    document.getElementById('editToolName').value = tool.Name;
    document.getElementById('editToolDescription').value = tool.Description;
    document.getElementById('editToolPrice').value = tool.PricePerDay;
    document.getElementById('editToolCategory').value = tool.Category;
    document.getElementById('editToolStatus').value = tool.AvailabilityStatus;

    
    document.getElementById('editToolLocation').value = tool.Location || '';
    document.getElementById('editDeliveryOption').value = tool.DeliveryOption || 'Pickup Only';
    toggleEditDeliveryPriceInput();

    
    document.getElementById('editDeliveryPrice').value = tool.DeliveryPrice || 0;

    
    const photosContainer = document.getElementById('existingPhotos');
    photosContainer.innerHTML = '';
    const photos = toolPhotosMap[tool.ToolID] || [];
    photos.forEach(photo => {
        const photoDiv = document.createElement('div');
        photoDiv.className = 'relative group rounded-lg overflow-hidden border border-gray-300';

        const img = document.createElement('img');
        img.src = '../../' + photo.PhotoPath;
        img.alt = 'Tool photo';
        img.className = 'w-full h-32 object-cover';

        const overlay = document.createElement('div');
        overlay.className = 'absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center space-x-2';

       
        if (!photo.IsPrimary) {
            const setPrimaryBtn = document.createElement('button');
            setPrimaryBtn.textContent = 'Set as Primary';
            setPrimaryBtn.className = 'bg-green-500 text-white px-2 py-1 rounded hover:bg-green-600 text-xs';
            setPrimaryBtn.onclick = () => setPrimaryPhoto(tool.ToolID, photo.PhotoID);
            overlay.appendChild(setPrimaryBtn);
        } else {
            const primaryLabel = document.createElement('div');
            primaryLabel.textContent = 'Primary Photo';
            primaryLabel.className = 'absolute top-1 left-1 bg-blue-500 text-white px-2 py-0.5 rounded text-xs';
            photoDiv.appendChild(primaryLabel);
        }

       
        const deleteBtn = document.createElement('button');
        deleteBtn.textContent = 'Delete';
        deleteBtn.className = 'bg-red-500 text-white px-2 py-1 rounded hover:bg-red-600 text-xs';
        deleteBtn.onclick = () => deletePhoto(tool.ToolID, photo.PhotoID);
        overlay.appendChild(deleteBtn);

        photoDiv.appendChild(img);
        photoDiv.appendChild(overlay);
        photosContainer.appendChild(photoDiv);
    });

    document.getElementById('editToolModal').classList.remove('hidden');
}


function hideEditToolModal() {
    document.getElementById('editToolModal').classList.add('hidden');
}


function showRentalDetailsModal(tool) {
    if (typeof tool === 'string') {
        try {
            tool = JSON.parse(tool);
        } catch (e) {
            console.error('Failed to parse tool JSON:', e);
            return;
        }
    }
    document.getElementById('rentalToolNameTitle').textContent = tool.Name;
    const rentalDetailsContainer = document.getElementById('rentalDetailsContainer');
    rentalDetailsContainer.innerHTML = '';

    const rentals = toolRentals[tool.ToolID] || [];
    if (rentals.length === 0) {
        rentalDetailsContainer.innerHTML = '<p class="text-gray-600">No rentals for this tool.</p>';
    } else {
        const list = document.createElement('ul');
        list.className = 'divide-y divide-gray-200';

        rentals.forEach(rental => {
            const item = document.createElement('li');
            item.className = 'py-2';

            const renterName = document.createElement('p');
            renterName.className = 'font-semibold';
            renterName.textContent = `Rented by: ${rental.FirstName} ${rental.LastName}`;

            const rentalPeriod = document.createElement('p');
            rentalPeriod.className = 'text-sm text-gray-600';
            rentalPeriod.textContent = `Period: ${new Date(rental.RentalStartDate).toLocaleDateString()} - ${new Date(rental.RentalEndDate).toLocaleDateString()}`;

            const status = document.createElement('p');
            status.className = 'text-sm text-gray-600';
            status.textContent = `Status: ${rental.Status}`;

            item.appendChild(renterName);
            item.appendChild(rentalPeriod);
            item.appendChild(status);

            list.appendChild(item);
        });

        rentalDetailsContainer.appendChild(list);
    }

    document.getElementById('rentalDetailsModal').classList.remove('hidden');
}


function hideRentalDetailsModal() {
    document.getElementById('rentalDetailsModal').classList.add('hidden');
}


function deleteTool(toolId) {
    if (!confirm('Are you sure you want to delete this tool? This action cannot be undone.')) return;
    fetch(`tools.php?ajax_action=delete_tool&tool_id=${toolId}`)
        .then(async response => {
            const text = await response.text();
            if (!response.ok) {
                alert('Failed to delete tool: Server returned status ' + response.status);
                console.error('Delete tool error response:', text);
                return;
            }
            try {
                const data = JSON.parse(text);
                if (data.success) {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('Failed to delete tool: ' + data.message);
                    console.error('Delete tool failure:', data);
                }
            } catch (e) {
                alert('Failed to delete tool: Invalid server response');
                console.error('Delete tool invalid JSON:', text);
            }
        })
        .catch(error => {
            alert('Failed to delete tool due to network error.');
            console.error('Delete tool network error:', error);
        });
}


function deletePhoto(toolId, photoId) {
    if (!confirm('Are you sure you want to delete this photo?')) return;
    fetch(`tools.php?ajax_action=delete_photo&tool_id=${toolId}&photo_id=${photoId}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert(data.message);
                location.reload();
            } else {
                alert('Failed to delete photo: ' + data.message);
            }
        })
        .catch(error => {
            alert('Failed to delete photo due to network error.');
            console.error('Delete photo error:', error);
        });
}


function setPrimaryPhoto(toolId, photoId) {
    fetch(`tools.php?ajax_action=set_primary&tool_id=${toolId}&photo_id=${photoId}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert(data.message);
                location.reload();
            } else {
                alert('Failed to set primary photo: ' + data.message);
            }
        })
        .catch(error => {
            alert('Failed to set primary photo due to network error.');
            console.error('Set primary photo error:', error);
        });
}


function validateToolForm(form) {
    const price = parseFloat(form.pricePerDay.value);
    if (isNaN(price) || price <= 0) {
        showAlert('Please enter a valid price per day.', 'error');
        return false;
    }
    return true;
}


function showAlert(message, type = 'success') {
    const alertDiv = document.createElement('div');
    alertDiv.textContent = message;
    alertDiv.className = type === 'success' ? 'bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4' : 'bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4';
    const container = document.querySelector('.container');
    container.insertBefore(alertDiv, container.firstChild);
    setTimeout(() => alertDiv.remove(), 4000);
}


function toggleDeliveryPriceInput() {
    const deliveryOption = document.getElementById('deliveryOption').value;
    const deliveryPriceContainer = document.getElementById('deliveryPriceContainer');
    if (deliveryOption === 'Delivery Available') {
        deliveryPriceContainer.style.display = 'block';
    } else {
        deliveryPriceContainer.style.display = 'none';
    }
}

l
function toggleEditDeliveryPriceInput() {
    const deliveryOption = document.getElementById('editDeliveryOption').value;
    const deliveryPriceContainer = document.getElementById('editDeliveryPriceContainer');
    if (deliveryOption === 'Delivery Available') {
        deliveryPriceContainer.style.display = 'block';
    } else {
        deliveryPriceContainer.style.display = 'none';
    }
}


window.onclick = function(event) {
    const addModal = document.getElementById('addToolModal');
    const editModal = document.getElementById('editToolModal');
    const rentalModal = document.getElementById('rentalDetailsModal');
    if (event.target === addModal) {
        hideAddToolModal();
    }
    if (event.target === editModal) {
        hideEditToolModal();
    }
    if (event.target === rentalModal) {
        hideRentalDetailsModal();
    }
}


document.addEventListener('DOMContentLoaded', () => {
    const container = document.querySelector('.container');

    container.addEventListener('click', (event) => {
        const target = event.target;

        if (target.matches('button.edit-tool-btn')) {
            const toolData = target.getAttribute('data-tool');
            showEditToolModal(toolData);
        } else if (target.matches('button.view-rentals-btn')) {
            const toolData = target.getAttribute('data-tool');
            showRentalDetailsModal(toolData);
        } else if (target.matches('button.delete-tool-btn')) {
            const toolId = target.getAttribute('data-tool-id');
            deleteTool(toolId);
        } else if (target.id === 'addToolBtn') {
            showAddToolModal();
        } else if (target.id === 'cancelAddTool') {
            hideAddToolModal();
        } else if (target.id === 'cancelEditTool' || target.id === 'closeEditToolModal') {
            hideEditToolModal();
        } else if (target.id === 'closeRentalDetailsModal') {
            hideRentalDetailsModal();
        }
    });
});
