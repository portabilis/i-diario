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

  DEFAULT_CLASS_NUMBER = 1

  def adjust_by_discipline_to_general
    classroom_id = 0
    discipline_id = 0

    daily_frequencies_by_type(FrequencyTypes::GENERAL).each do |daily_frequency|
      teacher = TeacherDisciplineClassroom.find_by(classroom_id: daily_frequency.classroom_id,
                                                   discipline_id: daily_frequency.discipline_id).teacher
      absence_type_definer = FrequencyTypeDefiner.new(daily_frequency.classroom, teacher)
      absence_type_definer.define!

      next if absence_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE

      if classroom_id != daily_frequency.classroom_id && discipline_id != daily_frequency.discipline_id
        classroom_id = daily_frequency.classroom_id
        discipline_id = daily_frequency.discipline_id

        next if daily_frequency_exists?(daily_frequency, nil, nil) && daily_frequency.destroy

        daily_frequency.update_columns(
          discipline_id: nil,
          class_number: nil
        )
      else
        daily_frequency.destroy
      end
    end
  end

  def adjust_general_to_by_discipline
    daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).each do |daily_frequency|
      teacher_user_id = Audited::Adapters::ActiveRecord::Audit.find_by(auditable_type: 'DailyFrequency',
                                                                       auditable_id: daily_frequency.id).user_id
      teacher_id = Teacher.find(User.find(teacher_user_id).teacher_id)
      discipline_id = daily_frequency.classroom.teacher_discipline_classrooms.find_by_teacher_id(teacher_id).try(:discipline_id) ||
                      daily_frequency.classroom.teacher_discipline_classrooms.first.try(:discipline_id)

      next if daily_frequency_exists?(daily_frequency, discipline_id) && daily_frequency.destroy

      daily_frequency.update_columns(
        discipline_id: discipline_id,
        class_number: DEFAULT_CLASS_NUMBER
      )
    end
  end

  def daily_frequencies_by_type(frequency_type)
    daily_frequencies = DailyFrequency.joins(:classroom)
                                      .merge(Classroom.joins(:exam_rule).where(exam_rules: { frequency_type: frequency_type }))
                                      .where('extract(year from frequency_date) = ?', @year)
                                      .where(unity_id: @unity_ids)

    daily_frequencies = daily_frequencies.where.not(discipline_id: nil) if frequency_type == FrequencyTypes::GENERAL
    daily_frequencies = daily_frequencies.where(discipline_id: nil) if frequency_type == FrequencyTypes::BY_DISCIPLINE

    daily_frequencies
  end

  def daily_frequency_exists?(daily_frequency, discipline_id, class_number = DEFAULT_CLASS_NUMBER)
    DailyFrequency.where(
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      frequency_date: daily_frequency.frequency_date,
      school_calendar_id: daily_frequency.school_calendar_id,
      discipline_id: discipline_id,
      class_number: class_number
    ).exists?
  end
end
