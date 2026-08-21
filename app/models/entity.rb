class Entity < ApplicationRecord
  acts_as_copy_target

  # Contexto do tenant ativo, thread-local (mesmo padrão de User.current).
  # Um cattr_accessor seria uma variável de classe única para o processo:
  # com Puma multi-thread ou Sidekiq, threads atendendo entidades diferentes
  # sobrescreveriam o tenant umas das outras (vazamento cross-tenant em
  # chaves de cache, paths de upload etc). A conexão ao banco já é
  # thread-local (gem activerecord-connections); este contexto acompanha.
  def self.current=(entity)
    Thread.current[:entity] = entity
  end

  def self.current
    Thread.current[:entity]
  end

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
    previous_entity = Entity.current
    # dup: get_context expõe o hash interno que o set_context muta — sem
    # cópia, a "foto" do contexto anterior mudaria junto.
    previous_context = Honeybadger.get_context&.dup
    Entity.current = self
    Honeybadger.context(entity: { name: name, id: id })

    ActiveRecord::Base.using_connection(id, connection_spec, &block)
  ensure
    Entity.current = previous_entity

    # A tag de tenant do Honeybadger acompanha o restore, senão blocos
    # aninhados/sequenciais no mesmo job deixam a tag apontando para a última
    # entidade enquanto Entity.current já voltou. Só em saída normal: se o
    # bloco levantou, o report acontece depois deste ensure e precisa ainda
    # apontar para a entidade que falhou. ($! também é não-nil dentro de
    # handlers de rescue, ex. sidekiq_retries_exhausted — ali o restore é
    # pulado e a tag fica na entidade do próprio bloco, que é a desejada.)
    # E só a chave :entity: clear! zeraria breadcrumbs e contexto alheio; sem
    # chave anterior, os limpadores por job/request do Honeybadger cobrem a
    # fronteira.
    if $!.nil? && previous_context&.key?(:entity)
      Honeybadger.context(entity: previous_context[:entity])
    end
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
