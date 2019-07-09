class BaseSchoolCalendarStepActivity
  private

  def frequencies_in_step(school_calendar_id, start_at, end_at)
    DailyFrequency.by_school_calendar_id(school_calendar_id)
                  .by_frequency_date_between(start_at, end_at)
  end

  def conceptual_exams_in_step(step_number, start_at, end_at)
    ConceptualExam.by_recorded_at_between(start_at, end_at)
                  .where(step_number: step_number)
  end

  def descriptive_exams_in_step(step_number, start_at, end_at)
    DescriptiveExam.by_recorded_at_between(start_at, end_at)
                   .where(step_number: step_number)
  end

  def recoveries_in_step(start_at, end_at)
    RecoveryDiaryRecord.by_recorded_at_between(start_at, end_at)
  end

  def transfer_notes_in_step(start_at, end_at)
    TransferNote.by_recorded_at_between(start_at, end_at)
  end

  def complementary_exams_in_step(step_number, start_at, end_at)
    ComplementaryExam.by_recorded_at_between(start_at, end_at)
                     .where(step_number: step_number)
  end
end
