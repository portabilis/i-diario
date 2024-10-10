class InfrequencyTrackingNotifier
  def self.notify!
    new.notify!
  end

  def notify!
    return if users_to_notify.blank?

    classrooms_with_absences.each do |classroom|
      school_dates = school_dates(end_at, classroom)
      start_at = school_dates.first

      students_with_absences(classroom.id, start_at).each do |student_id|
        InfrequencyTrackingTypes.list.each do |type|
          next if school_dates.empty?

          start_at = school_dates.first
          last_notification_date = last_notification_date(classroom.id, student_id, type) || start_at
          start_at = last_notification_date < start_at ? start_at : last_notification_date
          unique_daily_frequency_students = students_with_absences_query(start_at).by_student_id(student_id)
          absence_dates = unique_daily_frequency_students.map(&:frequency_date).sort

          notify_student_by_type(student_id, classroom, start_at, school_dates, absence_dates, type)
        end
      end
    end

    update_infrequency_tracking_materialized_views
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
                               .includes(:classroom)
  end

  def classrooms_with_absences
    @students_with_absences ||= students_with_absences_query.map(&:classroom).compact.uniq
  end

  def students_with_absences(classroom_id, start_at)
    students_with_absences_query(start_at).by_classroom_id(classroom_id).pluck(:student_id).uniq
  end

  def last_notification_date(classroom_id, student_id, type)
    InfrequencyTracking.by_classroom_id(classroom_id)
                       .by_student_id(student_id)
                       .by_notification_type(type)
                       .select('MAX(notification_date) AS notification_date')[0]
                       .notification_date
  end

  def school_dates(end_at, classroom)
    days = general_configuration.days_to_consider_alternate_absences
    school_dates = []

    classroom.grade_ids.each do |grade|
      school_dates << SchoolDayChecker.new(school_calendar(classroom), end_at, grade, classroom.id, nil)
                                      .school_dates_since(end_at, days)
                                      .sort
    end

    school_dates.flatten
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
    infrequency_tracking = InfrequencyTracking.create!(
      student_id: student_id,
      classroom_id: classroom_id,
      notification_date: Date.current,
      notification_data: notification_data,
      notification_type: infrequency_tracking_type
    )

    send_notification(infrequency_tracking, infrequency_tracking_type)
  end

  def send_notification(infrequency_tracking, type)
    SystemNotificationCreator.create!(
      source: infrequency_tracking,
      title: I18n.t('infrequency_tracking_notifier.title'),
      description: description_by_type(infrequency_tracking, type),
      users: users_to_notify(infrequency_tracking.classroom.unity_id)
    )
  end

  def description_by_type(infrequency_tracking, type)
    student = infrequency_tracking.student.name
    unity = infrequency_tracking.classroom.unity.name
    classroom = infrequency_tracking.classroom.description

    absences = case type
               when InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES
                 general_configuration.max_consecutive_absence_days
               when InfrequencyTrackingTypes::ALTERNATING_ABSENCES
                 general_configuration.max_alternate_absence_days
               end

    I18n.t(
      "infrequency_tracking_notifier.description.#{type}",
      student: student,
      unity: unity,
      classroom: classroom,
      absences: absences
    )
  end

  def users_to_notify(unity_id = nil)
    User.joins(:user_roles)
        .where(user_roles: {
                 role_id: RolePermission
                             .where(feature: :infrequency_trackings, permission: :change)
                             .select(:role_id)
               })
        .where('user_roles.unity_id IS NULL OR user_roles.unity_id = ?', unity_id)
  end

  def need_send_notification?(type, school_dates, absence_dates)
    return alternating_absences?(absence_dates) if type == InfrequencyTrackingTypes::ALTERNATING_ABSENCES

    consecutive_absences?(school_dates, absence_dates)
  end

  def absences_by_teacher(unique_daily_frequency_students, teacher_id)
    unique_daily_frequency_students.by_teacher_id(teacher_id)
                                   .pluck(:frequency_date)
                                   .map(&:to_s)
                                   .sort
  end

  def unique_daily_frequency_students_by_type(type, start_at, student_id, school_dates)
    if type == InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES
      students_with_absences_query(
        consecutive_school_dates(school_dates).last
      ).by_student_id(student_id)
    else
      students_with_absences_query(start_at).by_student_id(student_id)
    end
  end

  def notify_student_by_type(student_id, classroom, start_at, school_dates, absence_dates, type)
    return unless need_send_notification?(type, school_dates, absence_dates)

    unique_daily_frequency_students = unique_daily_frequency_students_by_type(
      type,
      start_at,
      student_id,
      school_dates
    )

    notification_data = []
    teacher_ids = unique_daily_frequency_students.map(&:absences_by).flatten.uniq

    teacher_ids.each do |teacher_id|
      absences = absences_by_teacher(unique_daily_frequency_students, teacher_id)

      notification_data << { teacher_id: teacher_id, absences: absences }
    end

    create_infrequency_tracking(
      student_id,
      classroom.id,
      notification_data,
      type
    )
  end

  def update_infrequency_tracking_materialized_views
    database = ActiveRecord::Base.connection_config[:database]

    UpdateInfrequencyTrackingMaterializedViewsWorker.perform_in(1.second, database)
  end
end
