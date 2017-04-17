class BackupFile
  class ConceptualExams < Base
    def filename
      "avalicoes_conceituais.csv"
    end

    protected

    def query
      ConceptualExam
    end
  end
end
