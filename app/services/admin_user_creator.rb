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
      create_admin_role
    end
  end

  def create_admin
    @admin_user = User.find_by(login: 'admin')

    return true if @admin_user.present?

    @admin_user = User.create!(
      login: 'admin',
      email: 'admin@domain.com.br',
      password: password,
      password_confirmation: password,
      status: 'active',
      kind: 'employee',
      admin: true,
      receive_news: false,
      first_name: 'Admin'
    )
  end

  def create_admin_role
    @role = Role.order(:id).find_by(access_level: 'administrator')

    if @role.blank?
      @role = Role.create(
        name: 'Administrador',
        access_level: 'administrator',
        author_id: @admin_user.try(:id)
      )
    end

    UserRole.find_or_initialize_by(
      role: @role,
      user: @admin_user
    ).save(validate: false)
  end

  def success
    @status = 'Usuário administrador criado com sucesso.'
  end

  def error
    @status = 'Não foi possível criar o usuário administrador.'
  end
end
