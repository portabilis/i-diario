class BackupFile
  class Users < Base
    def filename
      "usuarios.csv"
    end

    protected

    def query
      User.select(%Q(
        users.id,
        users.email,
        users.first_name,
        users.last_name,
        users.login,
        users.cpf,
        users.phone,
        users.authorize_email_and_sms,
        users.status
      ))
    end
  end
end
