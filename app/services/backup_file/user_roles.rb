class BackupFile
  class UserRoles < Base
    def filename
      "permissoes_do_usuario.csv"
    end

    protected

    def query
      UserRole
    end
  end
end
