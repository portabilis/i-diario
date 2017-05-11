class BackupFile
  class ObservationDiaryRecordNotes < Base
    def filename
      "observacoes_do_diario_de_observacoes.csv"
    end

    protected

    def query
      ObservationDiaryRecordNote
    end
  end
end
