class BackupFile
  class Roles < Base
    def filename
      "permissoes.csv"
    end

    protected

    def query
      Role
    end
  end
end
