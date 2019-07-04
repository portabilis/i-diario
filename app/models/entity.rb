class Entity < ActiveRecord::Base
  acts_as_copy_target

  validates :name, :domain, :config, presence: true
  validates :domain, uniqueness: { case_sensitive: false }, allow_blank: true

  scope :need_migration, -> { where(migrate: true) }
  scope :active, -> { where(disabled: false) }

  def using_connection(&block)
    Honeybadger.context(entity: { name: name, id: id })

    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  end

  protected

  def connection_spec
    config.dup.reverse_merge!(ActiveRecord::Base.connection_config.with_indifferent_access)
  end
end
