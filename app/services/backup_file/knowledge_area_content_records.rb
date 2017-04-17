class BackupFile
  class KnowledgeAreaContentRecords < Base
    def filename
      "registros_de_conteudo_por_area_de_conhecimento.csv"
    end

    protected

    def query
      KnowledgeAreaContentRecord
    end
  end
end
