$(document).ready( function() {
  let beta_title = 'Este recurso ainda está em processo de desenvolvimento e pode apresentar problemas'
  let img_src = $('#image-beta').attr('src');
  $('.fa-check-square-o').closest('h2').after(`<img src="${img_src}" class="beta-badge" style="margin-bottom: 9px; margin-left: 5px" title="${beta_title}">`);
})
