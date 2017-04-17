class BackupFile
  class DailyFrequencies < Base
    def filename
      "registro_diario_de_frequencia.csv"
    end

    protected

    def query
      DailyFrequency
    end
  end
end
