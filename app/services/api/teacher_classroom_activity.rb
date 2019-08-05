module Api
  class TeacherClassroomActivity
    def initialize(teacher_id, classroom_id)
      @teacher_id = teacher_id
      @classroom_id = classroom_id
    end

    def any_activity?
      return true if DailyNote.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      return true if DailyFrequency.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      return true if ConceptualExam.by_classroom_id(@classroom_id).by_teacher(@teacher_id).exists?

      return true if DescriptiveExam.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      return true if RecoveryDiaryRecord.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      return true if TransferNote.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      return true if ComplementaryExam.by_classroom_id(@classroom_id).by_teacher_id(@teacher_id).exists?

      false
    end
  end
end
