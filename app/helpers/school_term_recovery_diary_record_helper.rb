module SchoolTermRecoveryDiaryRecordHelper
  def school_term_recovery_diary_record_student_name_class(student_note)
    if student_note.student.exempted_from_discipline
      'exempted-student-from-discipline'
    else
      ''
    end
  end

  def school_term_recovery_diary_record_student_name(student_note)
    if student_note.student.exempted_from_discipline
      "*#{student_note.student.name}"
    else
      "#{student_note.student.name}"
    end
  end
end
