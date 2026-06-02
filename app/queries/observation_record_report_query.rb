class ObservationRecordReportQuery
  def initialize(unity_id, teacher_id, classroom_id, discipline_id, start_at, end_at, current_user_id, student_id = nil)
    @unity_id = unity_id
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
    @start_at = start_at.to_date
    @end_at = end_at.to_date
    @current_user_id = current_user_id
    @student_id = student_id
  end

  def observation_diary_records
    user = User.find(current_user_id)
    year = user.current_school_year

    if @classroom_id.eql?('all')
      @classroom_id = if user.teacher?
                        Classroom.by_unity_and_teacher(unity_id, user.teacher_id)
                                 .by_year(year)
                                 .pluck(:id)
                      else
                        Classroom.by_unity(unity_id)
                                 .by_year(year)
                                 .pluck(:id)
                      end
    end

    relation = ObservationDiaryRecord.includes(notes: :students)
                                     .by_classroom(classroom_id)
                                     .where(date: start_at..end_at)
                                     .order(:date)

    if @discipline_id.eql?('all') && user.teacher?
      teacher_discipline_ids = Discipline.by_teacher_id(user.teacher_id, year).pluck(:id)
      relation = relation.by_discipline(teacher_discipline_ids)
    elsif !@discipline_id.eql?('all')
      relation = relation.by_discipline(@discipline_id)
    end

    relation = relation.by_teacher(@teacher_id) if @teacher_id.present?
    relation = relation.by_student_id(@student_id).distinct if @student_id.present?

    relation
  end

  private

  attr_accessor :unity_id, :teacher_id, :classroom_id, :discipline_id, :start_at, :end_at, :current_user_id, :student_id
end
