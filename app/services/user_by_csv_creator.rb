class UserByCsvCreator
  attr_reader :file, :entity_name, :send_mail, :status

  def initialize(options)
    @file = options['FILE']
    @entity_name = options['ENTITY']
    @send_mail = options['EMAIL'].casecmp?('false') ? false : true
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
    entities = entity_name.casecmp?('ALL') ? Entity.all : Entity.where(name: entity_name)
    return false if entities.blank?

    entities.each do |entity|
      entity.using_connection do
        create_users(entity)
      end
    end
  end

  def file_not_found
    @status = 'arquivo não encontrado'
  end

  def create_users(entity)
    ActiveRecord::Base.transaction do
      CSV.foreach(file, col_sep: ',', skip_blanks: true) do |user|
        @user = User.find_by(login: user[3])
        next if @user.present?

        password = SecureRandom.hex(8)
        @user = User.create!(
          login: user[3],
          email: user[2],
          password: password,
          password_confirmation: password,
          status: 'active',
          kind: 'employee',
          admin: true,
          receive_news: false,
          first_name: user[0],
          last_name: user[1]
        )
        if set_admin_role && send_mail
          UserMailer.delay.by_csv(@user.login, @user.first_name, @user.email, password, entity.domain)
        end
      end
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
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
