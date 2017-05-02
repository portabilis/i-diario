class BackupFile
  class Classrooms < Base
    def filename
      "turmas.csv"
    end

    protected

    def query
      Classroom
    end
  end
end
