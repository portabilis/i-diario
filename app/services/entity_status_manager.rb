class EntityStatusManager
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def enable
    perform_action(:enable)
  end

  def disable
    perform_action(:disable)
  end

  private

  def has_params?
    name
  end

  def perform_action(action)
    if (has_params? && update_entity_status(action))
      success
    else
      error(action)
    end
  end

  def update_entity_status(action)
    entity = Entity.find_by_name(name)
    if entity
      entity.disabled = action.eql?(:disable)
      entity.save
    else
      false
    end
  end

  def success
    @status = I18n.t('services.entity_status_manager.success')
  end

  def error(action)
    @status = I18n.t('services.entity_status_manager.error', action: action)
  end
end
