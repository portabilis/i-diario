class Entity < ActiveRecord::Base
  acts_as_copy_target

  validates :name, :domain, :config, presence: true
  validates :domain, uniqueness: { case_sensitive: false }, allow_blank: true

  def self.current
    raise Exception.new("More than 1 entity registered") if all.count != 1

    all.first
  end

  def self.current_domain
    raise Exception.new("More than 1 entity registered") if all.count != 1

    all.first.domain
  end

  def using_connection(&block)
    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  end

  protected

  def connection_spec
    config.dup.reverse_merge!(ActiveRecord::Base.connection_config.with_indifferent_access)
  end
end
