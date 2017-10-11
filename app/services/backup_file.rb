class BackupFile
  def self.process!
    new.process!
  end

  def process!
    Zip::OutputStream.open(tempfile.path) do |zip|
      files.each do |file|
        zip.put_next_entry file.filename
        zip.print file.to_csv
      end
    end

    tempfile
  end

  protected

  def tempfile
    @tempfile ||= Tempfile.new([filename, ".zip"])
  end

  def filename
    "backup-#{DateTime.current}"
  end

  def files
    [
      BackupFile::AbsenceJustifications.new,
      BackupFile::Addresses.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::AvaliationExemptions.new,
      BackupFile::AvaliationRecoveryDiaryRecords.new,
      BackupFile::Avaliations.new,
      BackupFile::Classrooms.new,
      BackupFile::ConceptualExamValues.new,
      BackupFile::ConceptualExams.new,
      BackupFile::ContentRecords.new,
      BackupFile::Contents.new,
      BackupFile::Courses.new,
      BackupFile::DailyFrequencies.new,
      BackupFile::DailyFrequencyStudents.new,
      BackupFile::DailyNoteStudents.new,
      BackupFile::DailyNotes.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::DescriptiveExamStudents.new,
      BackupFile::DescriptiveExams.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::DisciplineContentRecords.new,
      BackupFile::DisciplineLessonPlans.new,
      BackupFile::DisciplineTeachingPlans.new,
      BackupFile::Disciplines.new,
      BackupFile::EntityConfigurations.new,
      BackupFile::ExamRules.new,
      BackupFile::FinalRecoveryDiaryRecords.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::GeneralConfigurations.new,
      BackupFile::Grades.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::KnowledgeAreaContentRecords.new,
      BackupFile::KnowledgeAreaLessonPlans.new,
      BackupFile::KnowledgeAreaTeachingPlans.new,
      BackupFile::KnowledgeAreas.new,
      BackupFile::LessonPlans.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***Requests.new,
      BackupFile::***REMOVED***RequestItems.new,
      BackupFile::***REMOVED***RequestAuthorizations.new,
      BackupFile::***REMOVED***RequestAuthorizationItems.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Menus.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Notifications.new,
      BackupFile::ObservationDiaryRecordNoteStudents.new,
      BackupFile::ObservationDiaryRecordNotes.new,
      BackupFile::ObservationDiaryRecords.new,
      BackupFile::Profiles.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::RecoveryDiaryRecordStudents.new,
      BackupFile::RecoveryDiaryRecords.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::RolePermissions.new,
      BackupFile::Roles.new,
      BackupFile::SchoolCalendarClassroomSteps.new,
      BackupFile::SchoolCalendarClassrooms.new,
      BackupFile::SchoolCalendarEvents.new,
      BackupFile::SchoolCalendarSteps.new,
      BackupFile::SchoolCalendars.new,
      BackupFile::School***REMOVED***s.new,
      BackupFile::SchoolTermRecoveryDiaryRecords.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Stock***REMOVED***.new,
      BackupFile::Students.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***es.new,
      BackupFile::TeacherDisciplineClassrooms.new,
      BackupFile::Teachers.new,
      BackupFile::TeachingPlans.new,
      BackupFile::TermsDictionaries.new,
      BackupFile::TestSettingTests.new,
      BackupFile::TestSettings.new,
      BackupFile::TransferNotes.new,
      BackupFile::Unities.new,
      BackupFile::UnityEquipments.new,
      BackupFile::UserRoles.new,
      BackupFile::Users.new
    ]
  end
end
