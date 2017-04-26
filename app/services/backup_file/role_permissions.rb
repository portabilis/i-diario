class BackupFile
  class RolePermissions < Base
    def filename
      "permissoes_da_permissao.csv"
    end

    protected

    def query
      RolePermission
    end
  end
end
