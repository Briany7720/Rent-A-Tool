document.addEventListener('DOMContentLoaded', function () {
    function updateCountdowns() {
        const timers = document.querySelectorAll('.countdown-timer');
        const now = new Date().getTime();

        timers.forEach(timer => {
            const endTimeStr = timer.getAttribute('data-endtime');
            const endTime = new Date(endTimeStr + 'T23:59:59').getTime(); 

            const distance = endTime - now;

            if (distance < 0) {
                timer.textContent = 'Overdue!';
                timer.classList.add('text-red-600', 'font-bold');
                
            } else {
                const days = Math.floor(distance / (1000 * 60 * 60 * 24));
                const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                const seconds = Math.floor((distance % (1000 * 60)) / 1000);

                timer.textContent = days + 'd ' + hours + 'h ' + minutes + 'm ' + seconds + 's';
            }
        });
    }

    updateCountdowns();
    setInterval(updateCountdowns, 1000);
});
