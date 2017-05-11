class BackupFile
  class TermsDictionaries < Base
    def filename
      "dicionarios_de_termos.csv"
    end

    protected

    def query
      TermsDictionary
    end
  end
end
