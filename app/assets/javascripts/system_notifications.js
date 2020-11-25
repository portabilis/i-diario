$(function () {
  var $dropdown = $('.notifications.ajax-dropdown');
  var readAllNotifications = function () {
    $.post(Routes.read_all_notifications_pt_br_path());
    $('#page-loading').addClass('hidden');
  };

  // ACTIVITY
  // ajax drop
  $('#activity').click(function(e) {
    var $this = $(this);

    if ($this.find('.badge').hasClass('bg-color-red')) {
      $this.find('.badge').removeClassPrefix('bg-color-');
      $this.find('.badge').text("0");
      // console.log("Ajax call for activity")
    }

    if (!$dropdown.is(':visible')) {
      $dropdown.fadeIn(150);
      $this.addClass('active');

      readAllNotifications();
    } else {
      $dropdown.fadeOut(150);
      $this.removeClass('active');
    }

    //clear memory reference
    $this = null;

    e.preventDefault();
  });

  $('input[name="activity"]').change(function() {
    //alert($(this).val())
    var $this = $(this);

    url = $this.attr('id');
    container = $('.ajax-notifications');

    loadURL(url, container);

    //clear memory reference
    $this = null;
  });

  // close dropdown if mouse is not inside the area of .ajax-dropdown
  $(document).mouseup(function(e) {
    if (!$dropdown.is(e.target) && $dropdown.has(e.target).length === 0) {
      $dropdown.fadeOut(150);
      $dropdown.prev().removeClass("active");
    }
  });

  // loading animation (demo purpose only)
  $('button[data-btn-loading]').on('click', function() {
    var btn = $(this);
    btn.button('loading');
    setTimeout(function() {
      btn.button('reset');
    }, 3000);

    //clear memory reference
    $this = null;
  });

  // NOTIFICATION IS PRESENT
  // Change color of lable once notification button is clicked

  $this = $('#activity > .badge');

  if (parseInt($this.text()) > 0) {
    $this.addClass("bg-color-red bounceIn animated");

    //clear memory reference
    $this = null;
  }
});
