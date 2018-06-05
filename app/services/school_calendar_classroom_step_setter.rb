class SchoolCalendarClassroomStepSetter
  def self.set_school_calendar_classroom_step(school_calendars)
    new(school_calendars).set_school_calendar_classroom_step
  end

  def initialize(school_calendars)
    @school_calendars = school_calendars
  end

  def set_school_calendar_classroom_step
    classroom_ids = SchoolCalendarClassroom.joins(:school_calendar)
                                           .where(school_calendars: { unity_id: @school_calendars['unity_id'] })
                                           .map(&:classroom_id)

    add_school_calendar_classroom_step_id(ConceptualExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil))
    add_school_calendar_classroom_step_id(DescriptiveExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil))
    add_school_calendar_classroom_step_id(TransferNote.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil))
    add_school_calendar_classroom_step_id_by_recorded_at(SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_ids).where(
                                                         school_calendar_classroom_step_id: nil))
  end

  private

  def add_school_calendar_classroom_step_id(items)
    items_to_keep = []

    items.each do |item|
      next unless item.school_calendar_step_id

      school_calendar_classroom_steps = find_classroom_steps(item.classroom_id)
      item.school_calendar_classroom_step_id = find_same_number_step(school_calendar_classroom_steps, item)
      item.save(validate: false)
      items_to_keep << item.id if item.school_calendar_classroom_step_id
    end

    items.where.not(id: items_to_keep).destroy_all
  end

  def add_school_calendar_classroom_step_id_by_recorded_at(items)
    items_to_keep = []

    items.each do |item|
      next unless item.school_calendar_step_id

      school_calendar_classroom_steps = find_classroom_steps(item.recovery_diary_record.classroom_id)
      recorded_at = item.recovery_diary_record.recorded_at
      item.school_calendar_classroom_step_id = school_calendar_classroom_steps.started_after_and_before(recorded_at).first.try(:id)
      item.save(validate: false)
      items_to_keep << item.id if item.school_calendar_classroom_step_id
    end

    items.where.not(id: items_to_keep).destroy_all
  end

  def find_same_number_step(classroom_steps, record)
    classroom_steps.detect { |step| step.to_number == record.school_calendar_step.to_number }.try(:id)
  end

  def find_classroom_steps(classroom_id)
    SchoolCalendarClassroomStep.joins(:school_calendar_classroom).where(school_calendar_classrooms: { classroom_id: classroom_id })
  end
end
