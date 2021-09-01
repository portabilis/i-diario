module DailyNoteHelper
  def do_undo_link(student, daily_note)
    exempted = student.exempted
    student_id = student.student_id
    target = if exempted
               undo_exemption_daily_note_path(daily_note,
                                              avaliation_id: daily_note.avaliation_id,
                                              student_id: student_id)
             else
               '#'
             end

    classes = 'btn'
    classes << ' btn-default undo-exemption' if exempted
    classes << ' btn-primary do-exemption open-exemption-modal' unless exempted

    data = exempted ? { remote: true, method: 'post' } : { student_id: student_id }

    link_to('', target, class: classes, data: data, style: 'float: right;', id: "do_undo_exemption_#{student_id}")
  end
end
