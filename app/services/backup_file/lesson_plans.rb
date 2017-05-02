class BackupFile
  class LessonPlans < Base
    def filename
      "planos_de_aula.csv"
    end

    protected

    def query
      LessonPlan
    end
  end
end
