class MaterializedViewRefresh < ApplicationRecord
  validates :view_name, presence: true, uniqueness: true
  validates :refreshed_at, presence: true

  def self.register!(view_name)
    record = find_or_initialize_by(view_name: view_name)
    record.update!(refreshed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique
    # Duas atualizações concorrentes da mesma view podem passar juntas pela
    # validação de unicidade e colidir no índice; na segunda passagem o registro
    # já existe e a atualização segue.
    retry
  end

  def self.refreshed_at_for(view_name)
    find_by(view_name: view_name)&.refreshed_at
  end
end
