class UserByCsv
  attr_reader :file, :entity_name, :status

  def initialize(options)
    @file = options['FILE']
    @entity_name = options['ENTITY']
  end

  def create
    return file_not_found unless File.exist?(file)
    return success if params? && create_user

    error
  end

  private

  def params?
    file && entity_name
  end

  def create_user
    entity = Entity.find_by(name: entity_name)

    return false if entity.blank?

    entity.using_connection do
      create_users
    end
  end

  def file_not_found
    @status = 'arquivo não encontrado'
  end

  def create_users
    begin
      ActiveRecord::Base.transaction do
        CSV.foreach(file, col_sep: ',', headers: true, skip_blanks: true) do |user|
          @user = User.find_by(login: user[0])
          next if @user.present?

          password = SecureRandom.hex(15)
          @user = User.create!(
            login: user[0],
            email: user[1],
            password: password,
            password_confirmation: password,
            status: 'active',
            kind: 'employee',
            admin: true,
            receive_news: false,
            first_name: user[2],
            last_name: user[3]
          )
          if set_admin_role
            UserMailer.delay.by_csv(@user.login, @user.first_name, @user.email, password, entity_name.capitalize)
          end
        end
        true
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def set_admin_role
    @role = Role.order(:id).find_by(access_level: 'administrator')

    if @role.blank?
      @role = Role.create(
        name: 'Administrador',
        access_level: 'administrator',
        author_id: @user.try(:id)
      )
    end

    UserRole.find_or_initialize_by(
      role: @role,
      user: @user
    ).save(validate: false)
  end

  def success
    @status = 'Usuários criados com sucesso.'
  end

  def error
    @status = 'Não foi possível criar os usuários.'
  end
end
