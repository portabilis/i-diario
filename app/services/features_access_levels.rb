class FeaturesAccessLevels
  def self.administrator_features
    Features.keys
  end

  def self.employee_features
    administrator_features - admin_only_features
  end

  def self.teacher_features
    [
      :begin,
      :accounts,
      :dashboard,
      :absence_justification_report,
      :absence_justifications,
      :attendance_record_report,
      :avaliation_exemptions,
      :avaliation_recovery_diary_records,
      :avaliations,
      :conceptual_exams,
      :conceptual_exams_in_batchs,
      :daily_frequencies,
      :daily_notes,
      :descriptive_exams,
      :discipline_content_records,
      :discipline_lesson_plan_report,
      :discipline_lesson_plans,
      :discipline_teaching_plans,
      :exam_record_report,
      :final_recovery_diary_records,
      :ieducar_api_exam_postings,
      :knowledge_area_content_records,
      :knowledge_area_lesson_plan_report,
      :knowledge_area_lesson_plans,
      :knowledge_area_teaching_plans,
      :observation_diary_records,
      :observation_record_report,
      :school_calendar_events,
      :school_calendars,
      :school_term_recovery_diary_records,
      :transfer_notes,
      :teacher_report_cards,
      :complementary_exams,
      :ieducar_api_exam_posting_without_restrictions,
      :change_school_year,
      :daily_frequencies_in_batchs,
      :learning_objectives_and_skills,
      :avaliation_recovery_lowest_notes,
      :attendance_record_report_by_students
    ]
  end

  def self.parent_features
    [
      :begin,
      :accounts,
      :dashboard
    ]
  end

  def self.student_features
    [
      :begin,
      :accounts,
      :dashboard
    ]
  end

  private

  def self.admin_only_features
    [
      :data_exportations,
      :entity_configurations,
      :general_configurations,
      :roles,
      :unities,
      :terms_dictionaries,
      :translations
    ]
  end
end
