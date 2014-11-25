class BackupFile
  class GeneralConfigurations < Base
    def filename
      "configuracoes_gerais.csv"
    end

    protected

    def query
      GeneralConfiguration
    end
  end
end
