class BackupFile
  class SchoolCalendarSteps < Base
    def filename
      "etapas_de_calendario_letivo.csv"
    end

    protected

    def query
      SchoolCalendarStep
    end
  end
end
