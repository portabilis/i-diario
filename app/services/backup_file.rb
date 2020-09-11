class BackupFile
  BACKUP_CLASSES = [
    'BackupFile::AbsenceJustifications',
    'BackupFile::Addresses',
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
    'BackupFile::DescriptiveExamStudents',
    'BackupFile::DescriptiveExams',
    'BackupFile::DisciplineContentRecords',
    'BackupFile::DisciplineLessonPlans',
    'BackupFile::DisciplineTeachingPlans',
    'BackupFile::Disciplines',
    'BackupFile::EntityConfigurations',
    'BackupFile::ExamRules',
    'BackupFile::FinalRecoveryDiaryRecords',
    'BackupFile::GeneralConfigurations',
    'BackupFile::Grades',
    'BackupFile::KnowledgeAreaContentRecords',
    'BackupFile::KnowledgeAreaLessonPlans',
    'BackupFile::KnowledgeAreaTeachingPlans',
    'BackupFile::KnowledgeAreas',
    'BackupFile::LessonPlans',
    'BackupFile::ObservationDiaryRecordNoteStudents',
    'BackupFile::ObservationDiaryRecordNotes',
    'BackupFile::ObservationDiaryRecords',
    'BackupFile::Profiles',
    'BackupFile::RecoveryDiaryRecordStudents',
    'BackupFile::RecoveryDiaryRecords',
    'BackupFile::RolePermissions',
    'BackupFile::Roles',
    'BackupFile::SchoolCalendarClassroomSteps',
    'BackupFile::SchoolCalendarClassrooms',
    'BackupFile::SchoolCalendarEvents',
    'BackupFile::SchoolCalendarSteps',
    'BackupFile::SchoolCalendars',
    'BackupFile::SchoolTermRecoveryDiaryRecords',
    'BackupFile::Students',
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
    'BackupFile::Users'
  ]

  def self.process_by_type!(type)
    return new.process_full_backup! if type == BackupTypes::FULL_SYSTEM_BACKUP

    new.process_school_calendar_backup!
  end

  def process_full_backup!
    Zip::OutputStream.open(tempfile.path) do |zip|
      files.each do |file|
        zip.put_next_entry file.filename
        zip.print file.to_csv
      end
    end

    tempfile
  end

  def process_school_calendar_backup!
    csv = CSV.generate_line(
      %w[
        escola
        tipo
        etapa
        nome_da_etapa
        turma
        data_inicial
        data_final
        data_inicial_para_postagem
        data_final_para_postagem
        avaliacoes_criadas
        avaliacoes_lancadas
        avaliacoes_conceituais_lancadas
        avaliacoes_descritivas_lancadas
        frequencias_lancadas
        planos_de_ensino_criados
        planos_de_ensino_anual
        notas_de_transferencia_criadas
        avaliacoes_complementares_lancadas
        recuperacoes_de_avaliacoes_lancadas
        recuperacoes_de_etapas_lancadas
      ]
    )

    school_calendar_items.each do |item|
      csv << CSV.generate_line(
        [
          item[0],
          item[1],
          item[2],
          item[3],
          item[4],
          item[5],
          item[6],
          item[7],
          item[8],
          item[9],
          item[10],
          item[11],
          item[12],
          item[13],
          item[14],
          item[15],
          item[16],
          item[17],
          item[18],
          item[19]
        ]
      )
    end

    Zip::OutputStream.open(tempfile.path) do |zip|
      zip.put_next_entry 'school_calendar_backup.csv'
      zip.print csv
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

  def school_calendar_items
    connection = ActiveRecord::Base.connection
    connection.select_rows(SchoolCalendarQuery.school_calendars_with_data_count)
  end
end
