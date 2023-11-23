function resend_posting(index, stepId) {

  const buttonId = 'btn-posting-' + index + '-' + stepId;
  let clickTracking = JSON.parse(localStorage.getItem('click-tracking'));

  if (clickTracking && clickTracking[buttonId]) {
    clickTracking[buttonId] = {
      ...clickTracking[buttonId],
      clicked: clickTracking[buttonId].clicked + 1,
    }
  } else {
    clickTracking = {
      ...clickTracking,
      [buttonId]: {
        clicked: 1,
        clicked_old: 0,
        timeout: 1800000,
        paid: 0
      }
    }
  }

  localStorage.setItem('click-tracking', JSON.stringify(clickTracking));
}

(function startData() {
  const clickTracking = JSON.parse(localStorage.getItem('click-tracking'));
  if (!clickTracking) return;

  Object.keys(clickTracking).forEach((key) => {
    const button = document.getElementById(key);
    if ((clickTracking[key].clicked > clickTracking[key].clicked_old) && (clickTracking[key].paid < clickTracking[key].timeout)) {
      const interval = setInterval(() => {
        let trackingFromStorage = JSON.parse(localStorage.getItem('click-tracking'));
        if (trackingFromStorage[key].paid >= trackingFromStorage[key].timeout) {
          trackingFromStorage[key] = {
            ...trackingFromStorage[key],
            clicked_old: trackingFromStorage[key].clicked,
          }
        } else {
          trackingFromStorage[key].paid += 1000;
        }
        localStorage.setItem('click-tracking', JSON.stringify(aux));
      }, 1000);

      if (button) button.style.pointerEvents = 'none';
      setTimeout(() => {
        if (button) button.style.pointerEvents = 'auto';
        let trackingFromStoragePaid = JSON.parse(localStorage.getItem('click-tracking'));
        trackingFromStoragePaid[key] = {
          ...trackingFromStoragePaid[key],
          clicked_old: trackingFromStoragePaid[key].clicked,
          paid: 0
        }

        clearInterval(interval);
        localStorage.setItem('click-tracking', JSON.stringify(trackingFromStoragePaid));
      }, clickTracking[key].timeout - clickTracking[key].paid);
    }
  });
})();

document.addEventListener("DOMContentLoaded", function () {
  var button = document.getElementById("send-button");
  var originalText = button.innerHTML;
  var disabled = false;

  button.addEventListener("click", function () {
    if (!disabled) {
      disabled = true;
      button.classList.add("disabled");
      setTimeout(function () {
        disabled = false;
        button.innerHTML = originalText;
        button.classList.remove("disabled");
      }, 20000); // 20 segundos em milissegundos
    }
  });
});

