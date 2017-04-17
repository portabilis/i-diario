class BackupFile
  class ObservationDiaryRecordNoteStudents < Base
    def filename
      "alunos_da_observacao_do_diario_de_observacoes.csv"
    end

    protected

    def query
      ObservationDiaryRecordNoteStudent
    end
  end
end
