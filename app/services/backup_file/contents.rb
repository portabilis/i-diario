class BackupFile
  class Contents < Base
    def filename
      "conteudos.csv"
    end

    protected

    def query
      Content
    end
  end
end
