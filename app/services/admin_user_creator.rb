class AdminUserCreator
  attr_reader :name, :password, :status

  def initialize(options)
    @name = options['NAME']
    @password = options['ADMIN_PASSWORD'] || Rails.application.secrets.ADMIN_PASSWORD
  end

  def create
    return success if params? && create_admin_user

    error
  end

  private

  def params?
    name && password
  end

  def create_admin_user
    entity = Entity.find_by(name: name)

    return false if entity.blank?

    entity.using_connection do
      create_admin
    end
  end

  def create_admin
    admin_user = User.find_by(login: 'admin')

    return true if admin_user.present?

    User.create!(
        login: 'admin',
        email: 'admin@domain.com.br',
        password: password,
        password_confirmation: password,
        status: 'active',
        kind: 'employee',
        admin:  true,
        receive_news: false
    )
  end

  def success
    @status = 'Usuário administrador criado com sucesso.'
  end

  def error
    @status = 'Não foi possível criar o usuário administrador.'
  end
end
