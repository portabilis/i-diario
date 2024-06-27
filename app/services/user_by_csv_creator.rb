class UserByCsvCreator
  class InvalidUserError < StandardError; end
  attr_reader :file, :entity_name, :send_mail, :status, :password

  def initialize(options)
    @file = options['FILE']
    @entity_name = options['ENTITY']
    @send_mail = options['EMAIL'].casecmp?('false') ? false : true
    @password = options['PASSWORD']
  end

  def create
    return file_not_found unless File.exist?(file)
    return success if params? && create_user

    error
  end

  private

  def params?
    file && entity_name && password
  end

  def create_user
    entities = entity_name.casecmp?('ALL') ? Entity.all : Entity.where(name: entity_name)
    return false if entities.blank?

    entities.each do |entity|
      entity.using_connection do
        puts "Iniciando criação de usuarios no ambiente #{entity.name}"
        return unless create_users(entity)
        puts "Usuários criados com sucesso no ambiente #{entity.name}"
      end
    end
  end

  def file_not_found
    @status = 'arquivo não encontrado'
  end

  def create_users(entity)
    errors = []
    ActiveRecord::Base.transaction do
      CSV.foreach(file, col_sep: ',', skip_blanks: true) do |new_user|
        User.find_or_initialize_by(login: new_user[3]).tap do |user|
          if new_user[5] == '0'
            user.destroy
            next
          end

          user.assign_attributes(login: new_user[3],
                                 email: new_user[2],
                                 password: password,
                                 password_confirmation: password,
                                 status: 'active',
                                 kind: 'employee',
                                 admin: true,
                                 receive_news: false,
                                 first_name: new_user[0],
                                 last_name: new_user[1])

          if user.changed? && !user.save
            errors << invalid_user_error(user)
            next
          end

          if set_admin_role(user) && send_mail
            UserMailer.delay.by_csv(user.login, user.first_name, user.email, password, entity.domain)
          end
        end
      end
      true
    end
    errors.empty? || puts(errors.join("\n"))
  rescue ActiveRecord::RecordInvalid
    false
  end

  def set_admin_role(user)
    @role = Role.order(:id).find_by(access_level: 'administrator')

    if @role.blank?
      @role = Role.create(
        name: 'Administrador',
        access_level: 'administrator',
        author_id: user.try(:id)
      )
    end

    UserRole.find_or_initialize_by(
      role: @role,
      user: user
    ).save(validate: false)
  end

  def success
    @status = 'Criação de usuários completa'
  end

  def error
    @status = 'Não foi possível criar os usuários.'
  end

  def invalid_user_error(user)
    "Não foi possivel criar os usuarios devido ao erro #{user.errors.messages} para o usuario #{user.login}"
  end
end
