module DailyNoteHelper
  def student_note_class(student_note)
    if student_note.dependence?
      'warning'
    elsif student_note.exempted
      'desactivated'
    else
      ''
    end
  end

  def student_name(student_note)
    if student_note.dependence?
      "*#{student_note.student.to_s}"
    elsif student_note.exempted
      "**#{student_note.student.to_s}"
    else
      "#{student_note.student.to_s}"
    end
  end
end
