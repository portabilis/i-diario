class BackupFile
  class Avaliations < Base
    def filename
      "avaliacoes.csv"
    end

    protected

    def query
      Avaliation
    end
  end
end
