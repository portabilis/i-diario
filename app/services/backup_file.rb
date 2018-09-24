class BackupFile
  BACKUP_CLASSES = [
    'BackupFile::AbsenceJustifications',
    'BackupFile::Addresses',
    'BackupFile::***REMOVED***s',
    'BackupFile::AvaliationExemptions',
    'BackupFile::AvaliationRecoveryDiaryRecords',
    'BackupFile::Avaliations',
    'BackupFile::Classrooms',
    'BackupFile::ConceptualExamValues',
    'BackupFile::ConceptualExams',
    'BackupFile::ContentRecords',
    'BackupFile::Contents',
    'BackupFile::Courses',
    'BackupFile::DailyFrequencies',
    'BackupFile::DailyFrequencyStudents',
    'BackupFile::DailyNoteStudents',
    'BackupFile::DailyNotes',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::DescriptiveExamStudents',
    'BackupFile::DescriptiveExams',
    'BackupFile::***REMOVED***s',
    'BackupFile::DisciplineContentRecords',
    'BackupFile::DisciplineLessonPlans',
    'BackupFile::DisciplineTeachingPlans',
    'BackupFile::Disciplines',
    'BackupFile::EntityConfigurations',
    'BackupFile::ExamRules',
    'BackupFile::FinalRecoveryDiaryRecords',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::GeneralConfigurations',
    'BackupFile::Grades',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::KnowledgeAreaContentRecords',
    'BackupFile::KnowledgeAreaLessonPlans',
    'BackupFile::KnowledgeAreaTeachingPlans',
    'BackupFile::KnowledgeAreas',
    'BackupFile::LessonPlans',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***Requests',
    'BackupFile::***REMOVED***RequestItems',
    'BackupFile::***REMOVED***RequestAuthorizations',
    'BackupFile::***REMOVED***RequestAuthorizationItems',
    'BackupFile::***REMOVED***s',
    'BackupFile::Menus',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::Notifications',
    'BackupFile::ObservationDiaryRecordNoteStudents',
    'BackupFile::ObservationDiaryRecordNotes',
    'BackupFile::ObservationDiaryRecords',
    'BackupFile::Profiles',
    'BackupFile::RecoveryDiaryRecordStudents',
    'BackupFile::RecoveryDiaryRecords',
    'BackupFile::***REMOVED***s',
    'BackupFile::RolePermissions',
    'BackupFile::Roles',
    'BackupFile::SchoolCalendarClassroomSteps',
    'BackupFile::SchoolCalendarClassrooms',
    'BackupFile::SchoolCalendarEvents',
    'BackupFile::SchoolCalendarSteps',
    'BackupFile::SchoolCalendars',
    'BackupFile::School***REMOVED***s',
    'BackupFile::SchoolTermRecoveryDiaryRecords',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***s',
    'BackupFile::Stock***REMOVED***',
    'BackupFile::Students',
    'BackupFile::***REMOVED***s',
    'BackupFile::***REMOVED***es',
    'BackupFile::TeacherDisciplineClassrooms',
    'BackupFile::Teachers',
    'BackupFile::TeachingPlans',
    'BackupFile::TermsDictionaries',
    'BackupFile::TestSettingTests',
    'BackupFile::TestSettings',
    'BackupFile::TransferNotes',
    'BackupFile::Unities',
    'BackupFile::UnityEquipments',
    'BackupFile::UserRoles',
    'BackupFile::Users',
  ]

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
    BACKUP_CLASSES.map{|backup_class| backup_class.constantize.new }
  end
end
