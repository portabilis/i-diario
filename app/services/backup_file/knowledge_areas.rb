class BackupFile
  class KnowledgeAreas < Base
    def filename
      "areas_de_conhecimento.csv"
    end

    protected

    def query
      KnowledgeArea
    end
  end
end
