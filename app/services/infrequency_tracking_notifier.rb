class InfrequencyTrackingNotifier
  def self.notify!
    new.notify!
  end

  def notify!
    return if users_to_notify.blank?

    classrooms_with_absences.each do |classroom|
      school_calendar = school_calendar(classroom)
      school_dates = school_dates(school_calendar, end_at, classroom)
      start_at = school_dates.first

      students_with_absences(classroom.id, start_at).each do |student_id|
        last_notification_date = last_notification_date(classroom.id, student_id) || start_at
        start_at = last_notification_date < start_at ? start_at : last_notification_date
        unique_daily_frequency_students = students_with_absences_query(start_at).by_student_id(student_id)
        absence_dates = unique_daily_frequency_students.map(&:frequency_date).sort

        InfrequencyTrackingTypes.list.each do |infrequency_tracking_type|
          notification = nil

          case infrequency_tracking_type
          when InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES
            notification = consecutive_absences?(school_dates, absence_dates)
            consecutive_start_at = consecutive_school_dates(school_dates).last
            unique_daily_frequency_students = students_with_absences_query(
              consecutive_start_at
            ).by_student_id(student_id)
          when InfrequencyTrackingTypes::ALTERNATING_ABSENCES
            notification = alternating_absences?(absence_dates)
            unique_daily_frequency_students = students_with_absences_query(start_at).by_student_id(student_id)
          end

          next if notification.blank?

          notification_data = []
          teacher_ids = unique_daily_frequency_students.map(&:absences_by).flatten.uniq

          teacher_ids.each do |teacher_id|
            absences = unique_daily_frequency_students.by_teacher_id(teacher_id)
                                                      .pluck(:frequency_date)
                                                      .map(&:to_s)
                                                      .sort

            notification_data << {
              teacher_id: teacher_id,
              absences: absences
            }
          end

          infrequency_tracking = create_infrequency_tracking(
            student_id,
            classroom.id,
            notification_data,
            infrequency_tracking_type
          )
          send_notification(infrequency_tracking, infrequency_tracking_type)
        end
      end
    end
  end

  private

  def general_configuration
    @general_configuration ||= GeneralConfiguration.current
  end

  def school_calendar(classroom)
    StepsFetcher.new(classroom).school_calendar
  end

  def end_at
    @end_at ||= Date.yesterday
  end

  def students_with_absences_query(start_at = nil)
    start_at ||= Date.current.beginning_of_year

    UniqueDailyFrequencyStudent.frequency_date_between(start_at, end_at)
                               .where(present: false)
  end

  def classrooms_with_absences
    students_with_absences_query.map(&:classroom).uniq
  end

  def students_with_absences(classroom_id, start_at)
    students_with_absences_query(start_at).by_classroom_id(classroom_id).pluck(:student_id).uniq
  end

  def last_notification_date(classroom_id, student_id)
    InfrequencyTracking.by_classroom_id(classroom_id)
                       .by_student_id(student_id)
                       .select('MAX(notification_date) AS notification_date')[0]
                       .notification_date
  end

  def school_dates(school_calendar, end_at, classroom)
    days = general_configuration.days_to_consider_alternate_absences

    SchoolDayChecker.new(
      school_calendar, end_at, classroom.grade_id, classroom.id, nil
    ).school_dates_list(
      end_at, days, :backward
    ).sort
  end

  def consecutive_school_dates(school_dates)
    max_days = general_configuration.max_consecutive_absence_days

    school_dates.reverse.slice(0, max_days)
  end

  def consecutive_absences?(school_dates, absence_dates)
    max_days = general_configuration.max_consecutive_absence_days
    consecutive_absences = absence_dates.reverse.slice(0, max_days)

    consecutive_school_dates(school_dates) == consecutive_absences
  end

  def alternating_absences?(absence_dates)
    max_days = general_configuration.max_alternate_absence_days

    absence_dates.count >= max_days
  end

  def create_infrequency_tracking(student_id, classroom_id, notification_data, infrequency_tracking_type)
    InfrequencyTracking.create!(
      student_id: student_id,
      classroom_id: classroom_id,
      notification_date: Date.current,
      notification_data: notification_data,
      notification_type: infrequency_tracking_type
    )
  end

  def send_notification(infrequency_tracking, type)
    SystemNotificationCreator.create!(
      source: infrequency_tracking,
      title: I18n.t('infrequency_tracking_notifier.title'),
      description: description_by_type(infrequency_tracking, type),
      users: users_to_notify
    )
  end

  def description_by_type(infrequency_tracking, type)
    student = infrequency_tracking.student.name
    unity = infrequency_tracking.classroom.unity.name
    classroom = infrequency_tracking.classroom.description
    absences = general_configuration.max_consecutive_absence_days if type == :consecutive_absences
    absences = general_configuration.max_alternate_absence_days if type == :alternating_absences

    I18n.t(
      "infrequency_tracking_notifier.description.#{type}",
      student: student,
      unity: unity,
      classroom: classroom,
      absences: absences
    )
  end

  def users_to_notify
    @users_to_notify ||= begin
      role_ids = RolePermission.where(feature: :infrequency_trackings).pluck(:role_id)
      UserRole.where(role_id: role_ids).map(&:user)
    end
  end
end
