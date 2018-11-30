$('#hide-menu span a').on('click', function (e) {
  $.root_.toggleClass("hidden-menu");
  $("html").toggleClass("hidden-menu-mobile-lock");
} );
