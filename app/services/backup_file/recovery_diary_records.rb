class BackupFile
  class RecoveryDiaryRecords < Base
    def filename
      "diario_de_recuperacoes.csv"
    end

    protected

    def query
      RecoveryDiaryRecord
    end
  end
end
