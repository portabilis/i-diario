class BackupFile
  class DailyNoteStudents < Base
    def filename
      "alunos_do_registro_diario_de_avaliacao.csv"
    end

    protected

    def query
      DailyNoteStudent
    end
  end
end
