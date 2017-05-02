class BackupFile
  class Grades < Base
    def filename
      "series.csv"
    end

    protected

    def query
      Grade
    end
  end
end
