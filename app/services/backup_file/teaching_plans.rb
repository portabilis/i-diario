class BackupFile
  class TeachingPlans < Base
    def filename
      "planos_de_ensino.csv"
    end

    protected

    def query
      TeachingPlan
    end
  end
end
