class BackupFile
  class RecoveryDiaryRecordStudents < Base
    def filename
      "alunos_do_diario_de_recuperacao.csv"
    end

    protected

    def query
      RecoveryDiaryRecordStudent
    end
  end
end
