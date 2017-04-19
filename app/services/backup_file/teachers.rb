class BackupFile
  class Teachers < Base
    def filename
      "professores.csv"
    end

    protected

    def query
      Teacher
    end
  end
end
