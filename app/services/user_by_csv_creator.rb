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
        puts "Usuários criados com sucesso no ambiente #{entity.name}"
      end
    end
  end

  def file_not_found
    @status = 'arquivo não encontrado'
  end

  def create_users(entity)
    ActiveRecord::Base.transaction do
      CSV.foreach(file, col_sep: ',', skip_blanks: true) do |new_user|
        unless User.exists?(email: new_user[2])
          User.find_or_initialize_by(login: new_user[3]).tap do |user|
            if new_user[5] == '0'
              user.destroy
              next
            end
            password = new_user[4] || SecureRandom.hex(8)
            user.login = new_user[3]
            user.email = new_user[2]

            user.password = password
            user.password_confirmation = password

            user.status = 'active'
            user.kind = 'employee'
            user.admin = true
            user.receive_news = false
            user.first_name = new_user[0]
            user.last_name = new_user[1]

            user.save!

            if set_admin_role(user) && send_mail && new_user[4].nil?
              UserMailer.delay.by_csv(user.login, user.first_name, user.email, password, entity.domain)
            end
          end
        end
      end
      true
    end
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
end
