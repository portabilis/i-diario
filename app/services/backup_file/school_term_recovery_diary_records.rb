class BackupFile
  class SchoolTermRecoveryDiaryRecords < Base
    def filename
      "recuperacoes_de_etapas_da_turma.csv"
    end

    protected

    def query
      SchoolTermRecoveryDiaryRecord
    end
  end
end
