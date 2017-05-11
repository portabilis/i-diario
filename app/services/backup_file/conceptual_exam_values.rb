class BackupFile
  class ConceptualExamValues < Base
    def filename
      "valores_da_avaliacao_conceitual.csv"
    end

    protected

    def query
      ConceptualExamValue
    end
  end
end
