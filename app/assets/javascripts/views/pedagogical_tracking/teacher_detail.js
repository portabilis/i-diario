$(document).on('click', 'a.open_classroom_detail_modal', function(){
  var unity_id = $('#search_unity_id').val();
  var classroom_id = $(this).data('classroom-id');
  var start_date = $('#search_start_date').val();
  var end_date = $('#search_end_date').val();

  $("#classroom-detail-modal").modal('show');

  var params = {
    unity_id: unity_id,
    classroom_id: classroom_id,
    start_date: start_date,
    end_date: end_date
  }

  $.getJSON(Routes.pedagogical_tracking_teachers_pt_br_path(params)).always(function (teachers) {
    teachers_select = _.map(teachers, function(teacher) {
      return { id: teacher['teacher_id'], text: teacher['teacher_name'] };
    });
    teachers_select.unshift({ id: 'empty', text: '' });
    $('#search_teacher_teacher_id').select2({ data: teachers_select });

    var $modal_resources_tbody = $('#teacher-modal-resocurces');

    if (!_.isEmpty(teachers)) {
      $('.no_record_found').remove();
    }

    $.each(teachers, function(_index, value ) {
      var html = JST['templates/pedagogical_tracking/modal_resources']({
        teacher_name: value['teacher_name'],
        frequency_percentage: value['frequency_percentage'],
        content_record_percentage: value['content_record_percentage']
      });

      $modal_resources_tbody.append(html);
    });
  });
});

if (_.isEmpty($('#search_teacher_frequency_operator').val())){
  $('#search_teacher_frequency_percentage').attr('readonly', true).val('');
}
if (_.isEmpty($('#search_teacher_content_record_operator').val())){
  $('#search_teacher_content_record_percentage').attr('readonly', true).val('');
}

$('form.teacher_percent_filterable_search_form input, form.teacher_percent_filterable_search_form input.select2').on('change',
  function (e){
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

    $.get(
      $('form.teacher_percent_filterable_search_form').attr('action'),
      $('form.teacher_percent_filterable_search_form').serialize(),
      null,
      'script'
    );

    return false;
  }
);
