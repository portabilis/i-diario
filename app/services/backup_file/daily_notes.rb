class BackupFile
  class DailyNotes < Base
    def filename
      "registros_diarios_de_avaliacoes.csv"
    end

    protected

    def query
      DailyNote
    end
  end
end
