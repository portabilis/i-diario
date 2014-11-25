class BackupFile
  class IeducarApiConfigurations < Base
    def filename
      "ieducar_api_configuracoes.csv"
    end

    protected

    def query
      IeducarApiConfiguration
    end
  end
end
