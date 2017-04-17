class BackupFile
  class DisciplineLessonPlans < Base
    def filename
      "planos_de_aula_por_disciplina.csv"
    end

    protected

    def query
      DisciplineLessonPlan
    end
  end
end
