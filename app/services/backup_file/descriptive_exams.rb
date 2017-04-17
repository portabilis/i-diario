class BackupFile
  class DescriptiveExams < Base
    def filename
      "avaliacoes_descritivas.csv"
    end

    protected

    def query
      DescriptiveExam
    end
  end
end
