class SchoolCalendarSynchronizerService
  def self.synchronize(school_calendar)
    new(school_calendar).synchronize
  end

  def initialize(school_calendar)
    @school_calendar = school_calendar
  end

  def synchronize
    school_calendar = SchoolCalendarsCreator.create!(@school_calendar) || SchoolCalendarsUpdater.update!(@school_calendar)

    if school_calendar
      set_assigned_teacher_for_users(school_calendar)
      set_classroom_and_discipline_for_users(school_calendar)

      SchoolCalendarClassroomStepSetter.set_school_calendar_classroom_step(school_calendar)
    end
  end

  private

  def set_assigned_teacher_for_users(school_calendar)
    set_assigned_teacher_by_school_calendar(school_calendar)
    set_assigned_teacher_by_school_calendar_classrooms(school_calendar)
  end

  def set_assigned_teacher_by_school_calendar(school_calendar)
    current_year = SchoolCalendar.by_unity_id(school_calendar['unity_id']).by_school_day(Date.today).first.try(:year)

    User.by_current_unity_id(school_calendar['unity_id']).each do |user|
      classrooms_in_school_calendar_classrooms = SchoolCalendarClassroom.joins(:classroom)
                                                                        .merge(Classroom.where(year: current_year))
                                                                        .map(&:classroom_id)
      teacher_current_classroom = TeacherDisciplineClassroom.joins(:classroom)
                                                            .merge(Classroom.where(year: current_year))
                                                            .where.not(classroom_id: classrooms_in_school_calendar_classrooms)
                                                            .where(teacher_id: user.assumed_teacher_id)

      if teacher_current_classroom.blank?
        user.update_column(:assumed_teacher_id, nil)
      end
    end
  end

  def set_assigned_teacher_by_school_calendar_classrooms(school_calendar)
    current_classroom_ids = SchoolCalendarClassroom.by_unity_id(school_calendar['unity_id']).joins(:classroom_steps)
                                                    .merge(SchoolCalendarClassroomStep.by_school_day(Date.today))
                                                    .map(&:classroom_id)

    User.by_current_unity_id(school_calendar['unity_id']).each do |user|
      teacher_current_classroom = TeacherDisciplineClassroom.where.not(classroom_id: current_classroom_ids)
                                                            .where(teacher_id: user.assumed_teacher_id)

      if teacher_current_classroom.blank? && SchoolCalendarClassroomStep.by_classroom(user.current_classroom_id).any?
        user.update_column(:assumed_teacher_id, nil)
      end
    end
  end

  def set_classroom_and_discipline_for_users(school_calendar)
    set_classroom_and_discipline_by_school_calendar(school_calendar)
    set_classroom_and_discipline_by_school_calendar_classrooms(school_calendar)
  end

  def set_classroom_and_discipline_by_school_calendar(school_calendar)
    current_year = SchoolCalendar.by_unity_id(school_calendar['unity_id']).by_school_day(Date.today).first.try(:year)

    User.by_current_unity_id(school_calendar['unity_id']).each do |user|
      classroom_year = Classroom.find_by_id(user.current_classroom_id).try(:year)

      if classroom_year && current_year != classroom_year && SchoolCalendarClassroomStep.by_classroom(user.current_classroom_id).empty?
        user.update_columns(
          current_classroom_id: nil,
          current_discipline_id: nil
        )
      end
    end
  end

  def set_classroom_and_discipline_by_school_calendar_classrooms(school_calendar)
    current_classroom_ids = SchoolCalendarClassroom.by_unity_id(school_calendar['unity_id']).joins(:classroom_steps)
                                                    .merge(SchoolCalendarClassroomStep.by_school_day(Date.today))
                                                    .map(&:classroom_id)

    User.by_current_unity_id(school_calendar['unity_id']).each do |user|
      exists_classroom_step = SchoolCalendarClassroomStep.by_classroom(user.current_classroom_id).any?

      if exists_classroom_step && !current_classroom_ids.include?(user.current_classroom_id)
        user.update_columns(
          current_classroom_id: nil,
          current_discipline_id: nil
        )
      end
    end
  end
end
