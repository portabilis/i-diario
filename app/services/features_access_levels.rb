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
      :***REMOVED***,
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
      :messages,
      :observation_diary_records,
      :observation_record_report,
      :***REMOVED***,
      :school_calendar_events,
      :school_calendars,
      :school_term_recovery_diary_records,
      :test_settings,
      :transfer_notes,
      :teacher_report_cards,
      :complementary_exams
    ]
  end

  def self.parent_features
    [
      :begin,
      :accounts,
      :dashboard,
      :***REMOVED***,
      :***REMOVED***,
      :messages,
      :***REMOVED***s,
      :***REMOVED***,
      :***REMOVED***
    ]
  end

  def self.student_features
    [
      :begin,
      :accounts,
      :dashboard,
      :***REMOVED***,
      :***REMOVED***,
      :messages,
      :***REMOVED***,
      :***REMOVED***
    ]
  end

  private
  def self.admin_only_features
    [
      :data_exportations,
      :entity_configurations,
      :general_configurations,
      :***REMOVED***,
      :***REMOVED***_configs,
      :roles,
      :unities,
      :terms_dictionaries
    ]
  end
end
