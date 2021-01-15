//= require setup
//= require batch-actions
//= require educacao-gmap
//= require_self

$(function () {
  "use strict"

  $('input[data-typeahead-url]').typeajax();

  $('.tagsinput').tagsinput({
    confirmKeys: [13, 188],
    trimValue: true
  });

  $(document).ajaxStart(function() {
    $('#page-loading').removeClass('hidden');
  });

  $(document).ajaxStop(function () {
    $('#page-loading').addClass('hidden');
  });

  $.extend($.validator.messages, {
    required: "não pode ficar em branco",
    email: "não é um email válido",
    date: "não é uma data válida",
    number: "não é um número válido",
    digits: "deve conter somente dígitos"
  });

  $('nav ul').jarvismenu({
    accordion : true,
    speed : 235,
    closedSign : '<em class="fa fa-plus-square-o"></em>',
    openedSign : '<em class="fa fa-minus-square-o"></em>'
  });

  $('#map-address').on('gmap-address:update', function (e, position) {
    var $latitude = $('input[id$=_latitude]'),
        $longitude = $('input[id$=_longitude]');

    $latitude.val(position.lat());
    $longitude.val(position.lng());
  });

  $('#map-address').gmapAddress();

  $('[data-toggle=popover]').popover({
    trigger: 'focus'
  });

  $('#widget-grid').jarvisWidgets({
    grid : 'article',
    widgets : '.jarviswidget',
    sortable: false,
    toggleButton: false,
    deleteButton: false,
    editButton : false,
    colorButton : false,
    fullscreenButton : !window.fullscreen_disabled,
    fullscreenClass : 'fa fa-expand | fa fa-compress',
    fullscreenDiff : 3,
    onFullscreen : function() {
    }
  });

  $('#students').on('click', 'a', function (e) {
    e.preventDefault();
  });

  $('body').on('click', 'table.selectable tbody tr', function (e) {
    if (!_.include(["radio", "checkbox", "label"], $(e.target).attr('type'))) {
      var $el = $(this),
          $input = $el.find('input.select-target');

      if ($input.prop('checked')) {
        $input.prop('checked', false);
      } else {
        $input.prop('checked', 'checked');
      }
    }
  });

  $('.jarviswidget-fullscreen-btn').attr('data-original-title', 'Tela cheia');

  $('#select-all').on("click", function () {
    var checkboxes = $(this).closest("table").find("tbody tr td > input[type=checkbox]");

    checkboxes.prop("checked", $(this).prop('checked'));
  });

  var
      $online = $('.online'),
      $offline = $('.offline');

  Offline.on('confirmed-down', function () {
    $('#page-loading').removeClass('hidden');
    $online.fadeOut(function () {
        $offline.fadeIn();
    });
  });

  Offline.on('confirmed-up', function () {
    $('#page-loading').addClass('hidden');
    $offline.fadeOut(function () {
        $online.fadeIn();
    });
  });

  var link = $('.a-rotational-caret');
  var icon = $('.rotational-caret');
  var open = false;

  link.on('click', function(){
    if(open){
      icon.addClass('rotational-caret-close');
      icon.removeClass('rotational-caret-open');
    } else{
      icon.addClass('rotational-caret-open');
      icon.removeClass('rotational-caret-close');
    }

    open = !open;
  });
});
