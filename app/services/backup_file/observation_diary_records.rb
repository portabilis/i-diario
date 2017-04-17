class BackupFile
  class ObservationDiaryRecords < Base
    def filename
      "registro_do_diaro_de_obeservacoes.csv"
    end

    protected

    def query
      ObservationDiaryRecord
    end
  end
end
