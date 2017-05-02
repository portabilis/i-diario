class BackupFile
  class DescriptiveExamStudents < Base
    def filename
      "alunos_de_avaliacao_descritiva.csv"
    end

    protected

    def query
      DescriptiveExamStudent
    end
  end
end
