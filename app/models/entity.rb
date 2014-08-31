class Entity < ActiveRecord::Base
  validates :name, :domain, :config, presence: true
  validates :domain, uniqueness: { case_sensitive: false }, allow_blank: true

  def using_connection(&block)
    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  end

  protected

  def connection_spec
    config.dup.reverse_merge!(ActiveRecord::Base.connection_config.with_indifferent_access)
  end
end
