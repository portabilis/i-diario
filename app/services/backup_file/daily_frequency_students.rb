class BackupFile
  class DailyFrequencyStudents < Base
    def filename
      "alunos_do_registro_diario_de_frequencia.csv"
    end

    protected

    def query
      DailyFrequencyStudent
    end
  end
end
