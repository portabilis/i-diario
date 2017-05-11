class BackupFile
  class Courses < Base
    def filename
      "cursos.csv"
    end

    protected

    def query
      Course
    end
  end
end
