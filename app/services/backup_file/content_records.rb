class BackupFile
  class ContentRecords < Base
    def filename
      "registros_de_conteudos.csv"
    end

    protected

    def query
      ContentRecord
    end
  end
end
