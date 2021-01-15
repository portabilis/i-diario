$(document).on('click', 'a.open_classroom_detail_modal', function(){
  $('#modal_classroom_id').val($(this).data('classroom-id'));
  $('#search_teacher_frequency_operator').select2('val', '');
  $('#search_teacher_content_record_operator').select2('val', '');
  $('#search_teacher_frequency_percentage').attr('readonly', true).val('');
  $('#search_teacher_content_record_percentage').attr('readonly', true).val('');
  load_teachers(true);
});

if (_.isEmpty($('#search_teacher_frequency_operator').val())){
  $('#search_teacher_frequency_percentage').attr('readonly', true).val('');
}
if (_.isEmpty($('#search_teacher_content_record_operator').val())){
  $('#search_teacher_content_record_percentage').attr('readonly', true).val('');
}

$('form.teacher_percent_filterable_search_form input,\
  form.teacher_percent_filterable_search_form input.select2').on('change', function (e){
    clear_empty(e);

    if (this.id == 'search_teacher_frequency_operator') {
      if (_.isEmpty($('#search_teacher_frequency_operator').val())){
        $('#search_teacher_frequency_percentage').attr('readonly', true).val('');
      } else {
        $('#search_teacher_frequency_percentage').removeAttr('readonly');
        $('#search_teacher_frequency_percentage').focus();
      }
    }

    if (this.id == 'search_teacher_content_record_operator') {
      if (_.isEmpty($('#search_teacher_content_record_operator').val())){
        $('#search_teacher_content_record_percentage').attr('readonly', true).val('');
      } else {
        $('#search_teacher_content_record_percentage').removeAttr('readonly');
        $('#search_teacher_content_record_percentage').focus();
      }
    }

    if ((this.id == 'search_teacher_frequency_percentage' &&
         _.isEmpty($('#search_teacher_frequency_percentage').val())) ||
        (this.id == 'search_teacher_content_record_percentage' &&
         _.isEmpty($('#search_teacher_content_record_percentage').val()))) {
      return false;
    }

    if ((this.id == 'search_teacher_frequency_operator' &&
         _.isEmpty($('#search_teacher_frequency_percentage').val()) &&
         !($('#search_teacher_frequency_percentage').attr('readonly'))) ||
        (this.id == 'search_teacher_content_record_operator' &&
         _.isEmpty($('#search_teacher_content_record_percentage').val()) &&
         !($('#search_teacher_frequency_percentage').attr('readonly')))) {
      return false;
    }

    load_teachers();
  }
);

var empty_html = '<tr><td class="no_record_found" colspan="4">Nenhum registro encontrado</td></tr>';

function load_teachers(load_teachers_select2 = false){
  var $modal_resources_tbody = $('#teacher-modal-resocurces');
  $('.modal .tooltip').remove();
  $modal_resources_tbody.empty();

  var unity_id = $('#search_unity_id').val();
  var classroom_id = $('#modal_classroom_id').val();
  var teacher_id = $('#search_teacher_teacher_id').val();
  var start_date = $('#search_start_date').val();
  var end_date = $('#search_end_date').val();
  var frequency_operator = $('#search_teacher_frequency_operator').val();
  var frequency_percentage = $('#search_teacher_frequency_percentage').val();
  var content_record_operator = $('#search_teacher_content_record_operator').val();
  var content_record_percentage = $('#search_teacher_content_record_percentage').val();

  $("#classroom-detail-modal").modal('show');

  if (load_teachers_select2 || teacher_id == '') {
    teacher_id = null;
  }

  var params = {
    unity_id: unity_id,
    classroom_id: classroom_id,
    teacher_id: teacher_id,
    start_date: start_date,
    end_date: end_date,
    frequency_operator: frequency_operator,
    frequency_percentage: frequency_percentage,
    content_record_operator: content_record_operator,
    content_record_percentage: content_record_percentage
  }

  $.getJSON(Routes.pedagogical_trackings_teachers_pt_br_path(params)).always(function (teachers) {
    if (load_teachers_select2) {
      load_select2(teachers)
    }

    if (_.isEmpty(teachers)) {
      $modal_resources_tbody.append(empty_html);
    }

    $.each(teachers, function(_index, value ) {
      var html = JST['templates/pedagogical_trackings/modal_resources']({
        teacher_name: value['teacher_name'],
        frequency_percentage: value['frequency_percentage'],
        content_record_percentage: value['content_record_percentage'],
        frequency_days: value['frequency_days'],
        content_record_days: value['content_record_days']
      });

      $modal_resources_tbody.append(html);
    });

    $('.apply_tooltip').tooltip({ placement: 'top', container: '.modal'});
  });
}

function load_select2(teachers){
  $('#search_teacher_teacher_id').val('');
  teachers_select = _.map(teachers, function(teacher) {
    return { id: teacher['teacher_id'], text: teacher['teacher_name'] };
  });
  teachers_select.unshift({ id: 'empty', text: '' });
  $('#search_teacher_teacher_id').select2({ data: teachers_select });
}
