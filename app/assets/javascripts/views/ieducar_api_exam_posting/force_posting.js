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
          if (clickTracking[key].paid >= clickTracking[key].timeout) {
            clickTracking[key] = {
              ...clickTracking[key],
              clicked_old: clickTracking[key].clicked,
            }
          } else {
            clickTracking[key].paid += 1000;
          }

          localStorage.setItem('click-tracking', JSON.stringify(clickTracking));
        }, 1000);

        if (button) button.style.pointerEvents = 'none';
        setTimeout(() => {
          if (button) button.style.pointerEvents = 'auto';

          clickTracking[key] = {
            ...clickTracking[key],
            clicked_old: clickTracking[key].clicked,
            paid: 0
          }

          clearInterval(interval);

          localStorage.setItem('click-tracking', JSON.stringify(clickTracking));
        }, clickTracking[key].timeout - clickTracking[key].paid);
      }
    });
  })();
