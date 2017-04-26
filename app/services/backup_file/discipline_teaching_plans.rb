class BackupFile
  class DisciplineTeachingPlans < Base
    def filename
      "planos_de_ensino_por_disciplina.csv"
    end

    protected

    def query
      DisciplineTeachingPlan
    end
  end
end
