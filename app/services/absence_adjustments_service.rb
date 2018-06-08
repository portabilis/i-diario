class AbsenceAdjustmentsService
  def self.adjust(unity_ids, year)
    new(unity_ids, year).adjust
  end

  def initialize(unity_ids, year)
    @unity_ids = unity_ids
    @year = year
  end

  def adjust
    adjust_by_discipline_to_general
    adjust_general_to_by_discipline
  end

  private

  def adjust_by_discipline_to_general
    daily_frequencies_to_destroy = []
    daily_frequencies = DailyFrequency.joins(:classroom).merge(Classroom.joins(:exam_rule)
                                      .merge(ExamRule.where(frequency_type: FrequencyTypes::GENERAL)))
                                      .where('extract(year from frequency_date) = ?', @year)
                                      .where(unity_id: @unity_ids)
                                      .where.not(discipline_id: nil)

    classroom_id = 0
    discipline_id = 0
    absence_type_definer = nil

    daily_frequencies.each do |daily_frequency|
      if classroom_id != daily_frequency.classroom_id && discipline_id != daily_frequency.discipline_id
        teacher = TeacherDisciplineClassroom.where(classroom_id: daily_frequency.classroom_id,
                                                   discipline_id: daily_frequency.discipline_id).first.teacher
        absence_type_definer = FrequencyTypeDefiner.new(daily_frequency.classroom, teacher)
        absence_type_definer.define!

        classroom_id = daily_frequency.classroom_id
        discipline_id = daily_frequency.discipline_id

        unless (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)
          daily_frequency.update_columns(
            discipline_id: nil,
            class_number: nil
          )
        end
      else
        daily_frequencies_to_destroy << daily_frequency unless (absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE)
      end
    end

    daily_frequencies_to_destroy.each(&:destroy)
  end

  def adjust_general_to_by_discipline
    daily_frequencies = DailyFrequency.joins(:classroom).merge(Classroom.joins(:exam_rule)
                                      .merge(ExamRule.where(frequency_type: FrequencyTypes::BY_DISCIPLINE)))
                                      .where('extract(year from frequency_date) = ?', @year)
                                      .where(unity_id: @unity_ids)
                                      .where(discipline_id: nil)

    daily_frequencies.each do |daily_frequency|
      teacher_user_id = Audited::Adapters::ActiveRecord::Audit.where(auditable_type: 'DailyFrequency',
                                                                     auditable_id: daily_frequency.id).first.user_id
      teacher_id = Teacher.find(User.find(teacher_user_id).teacher_id)
      discipline_id = daily_frequency.classroom.teacher_discipline_classrooms.find_by_teacher_id(teacher_id).discipline_id ||
                      daily_frequency.classroom.teacher_discipline_classrooms.first.discipline_id

      daily_frequency.update_columns(
        discipline_id: discipline_id,
        class_number: 1
      )
    end
  end
end
