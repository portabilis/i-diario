class Entity < ActiveRecord::Base
  acts_as_copy_target

  cattr_accessor :current

  validates :name, :domain, :config, presence: true
  validates :domain, uniqueness: { case_sensitive: false }, allow_blank: true

  def self.current_domain
    raise Exception.new("Entity not found") if self.current.blank?

    self.current.domain
  end

  def using_connection(&block)
    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  end

  protected

  def connection_spec
    config.dup.reverse_merge!(ActiveRecord::Base.connection_config.with_indifferent_access)
  end
end
