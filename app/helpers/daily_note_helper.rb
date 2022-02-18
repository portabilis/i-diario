module DailyNoteHelper
  def do_undo_link(student, daily_note)
    exempted = student.exempted
    student_id = student.student_id
    target = if exempted && !student.in_active_search
               undo_exemption_daily_note_path(daily_note,
                                              avaliation_id: daily_note.avaliation_id,
                                              student_id: student_id)
             else
               '#'
             end

    classes = 'btn'
    classes << ' btn-default undo-exemption' if exempted
    classes << ' btn-primary do-exemption open-exemption-modal' unless exempted
    classes << ' readonly' if student.in_active_search
    title = exempted ? 'Desfazer' : 'Dispensar'
    data = exempted && !student.in_active_search ? { remote: true, method: 'post' } : { student_id: student_id }
    styles = 'float: right;'
    styles << ' pointer-events: none;' if student.in_active_search

    link_to('', target, class: classes, title: title, data: data, style: styles,
                        id: "do_undo_exemption_#{student_id}")
  end
end
