class BackupFile
  class SchoolCalendarEvents < Base
    def filename
      "eventos_do_calendario_letivo.csv"
    end

    protected

    def query
      SchoolCalendarEvent
    end
  end
end
