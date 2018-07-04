class EntityCreator
  attr_reader :name, :domain, :database, :status, :host, :db_user, :db_password

  def initialize(options)
    @name = options["NAME"]
    @domain = options["DOMAIN"]
    @database = options["DATABASE"]
    @host = options["HOST"]
    @db_user = options["DB_USER"]
    @db_password = options["DB_PASSWORD"]
  end

  def setup
    if (has_params? && create_entity)
      EntityDatabaseCreator.create(@database)

      success
    else
      error
    end
  end

  protected

  def has_params?
    name && domain && database
  end

  def create_entity
    entity = entity_repository.new(
      name: name,
      domain: domain,
      config: entity_config
    )

    entity.save
  end

  def entity_config
    config = {database: database}
    config.merge!({host: host}) if host.present?
    config.merge!({username: db_user}) if db_user.present?
    config.merge!({password: db_password}) if db_password.present?

    config
  end

  def entity_repository
    Entity
  end

  def success
    @status = I18n.t('services.entity_creator.success')
  end

  def error
    @status = I18n.t('services.entity_creator.error')
  end
end
