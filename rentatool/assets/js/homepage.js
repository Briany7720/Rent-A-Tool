document.addEventListener('click', function(event) {
    const target = event.target;
    if (target.classList.contains('btn')) {
        const text = target.textContent.trim().toLowerCase();
        if (text === 'rent now' || text === 'view all') {
            event.preventDefault();
            console.log('Login prompt triggered for button:', text);
            window.showAlert('You must be logged in to perform this action.', 'error');
        }
    }
});
