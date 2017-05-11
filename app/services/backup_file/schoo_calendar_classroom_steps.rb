class BackupFile
  class SchoolCalendarClassroomSteps < Base
    def filename
      "etapas_de_calendario_letivo_da_turma.csv"
    end

    protected

    def query
      SchoolCalendarClassroomStep
    end
  end
end
