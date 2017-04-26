class BackupFile
  class KnowledgeAreaTeachingPlans < Base
    def filename
      "planos_de_ensino_por_area_de_conhecimento.csv"
    end

    protected

    def query
      KnowledgeAreaTeachingPlan
    end
  end
end
