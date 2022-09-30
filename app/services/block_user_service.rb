class BlockUserService
  attr_reader :users, :entity_name, :status

  def initialize(options)
    @users = options['USERS']&.split(/\s*,\s*/)
    @entity_name = options['ENTITY'].present? ? options['ENTITY'] : 'ALL'
  end

  def block
    return success if params? && block_users

    error
  end

  private

  def params?
    users && entity_name
  end

  def block_users
    entities = entity_name.casecmp?('ALL') ? Entity.all : Entity.where(name: entity_name)
    return false if entities.blank?

    entities.each do |entity|
      entity.using_connection do
        block_users_by_entity(entity)
      end
    end
  end

  def block_users_by_entity(entity)
    @users.each do |email|
      user = User.find_by(email: email)
      if user.present?
        user.update_status(UserStatus::PENDING)
        puts 'Usuário ' + email + ' bloqueado em ' + entity.name
      end
    end
  end

  def success
    @status = 'Usuários bloqueados com sucesso.'
  end

  def error
    @status = 'Não foi possível bloquear os usuários.'
  end
end
