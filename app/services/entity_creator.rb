class EntityCreator
  attr_reader :name, :domain, :database, :status

  def initialize(options)
    @name = options["NAME"]
    @domain = options["DOMAIN"]
    @database = options["DATABASE"]
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
      config: { database: database }
    )

    entity.save
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
