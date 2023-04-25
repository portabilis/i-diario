class Entity < ApplicationRecord
  acts_as_copy_target

  cattr_accessor :current

  validates :name, :domain, :config, presence: true
  validates :domain, uniqueness: { case_sensitive: false }, allow_blank: true

  scope :active, -> { where(disabled: false) }
  scope :to_sync, -> { active.where(disabled_sync: false) }
  scope :enable_to_sync, -> { active.to_sync }

  def self.current_domain
    raise Exception.new("Entity not found") if self.current.blank?

    self.current.domain
  end

  def using_connection(&block)
    Entity.current = self
    Honeybadger.context(entity: { name: name, id: id })

    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  end

  def self.establish_connection(entity)
    Entity.current = entity
    ActiveRecord::Base.establish_connection entity.send(:connection_spec)
  end

  def self.connect(tenant)
    entity = find_by(name: tenant)

    raise Exception, 'Entity not found' if entity.blank?

    establish_connection(entity)
  end

  protected

  def connection_spec
    config.dup.reverse_merge!(ActiveRecord::Base.connection_config.with_indifferent_access)
  end
end
