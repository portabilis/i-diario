class BackupFile
  class SchoolCalendars < Base
    def filename
      "calendarios_letivos.csv"
    end

    protected

    def query
      SchoolCalendar
    end
  end
end
