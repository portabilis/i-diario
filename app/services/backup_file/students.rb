class BackupFile
  class Students < Base
    def filename
      "alunos.csv"
    end

    protected

    def query
      Student
    end
  end
end
