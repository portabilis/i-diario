class BackupFile
  class EntityConfigurations < Base
    def filename
      "configuracoes_da_entidade.csv"
    end

    protected

    def query
      EntityConfiguration
    end
  end
end
