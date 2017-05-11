class BackupFile
  class KnowledgeAreaLessonPlans < Base
    def filename
      "planos_de_aula_por_area_de_conhecimento.csv"
    end

    protected

    def query
      KnowledgeAreaLessonPlan
    end
  end
end
