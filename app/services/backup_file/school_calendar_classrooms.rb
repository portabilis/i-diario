class BackupFile
  class SchoolCalendarClassrooms < Base
    def filename
      "calendario_letivo_de_turmas.csv"
    end

    protected

    def query
      SchoolCalendarClassroom
    end
  end
end
