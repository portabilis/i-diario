class BackupFile
  class AvaliationRecoveryDiaryRecords < Base
    def filename
      "diario_de_recuperacao_de_avaliacoes.csv"
    end

    protected

    def query
      AvaliationRecoveryDiaryRecord
    end
  end
end
