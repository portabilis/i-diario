class BackupFile
  class FinalRecoveryDiaryRecords < Base
    def filename
      "diario_de_recuperacoes_finais.csv"
    end

    protected

    def query
      FinalRecoveryDiaryRecord
    end
  end
end
