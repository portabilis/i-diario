class BackupFile
  class AvaliationExemptions < Base
    def filename
      "dispensa_de_avaliacoes.csv"
    end

    protected

    def query
      AvaliationExemption
    end
  end
end
