class MaterializedViewRefresh < ApplicationRecord
  validates :view_name, presence: true, uniqueness: true
  validates :refreshed_at, presence: true

  def self.register!(view_name)
    record = find_or_initialize_by(view_name: view_name)
    record.update!(refreshed_at: Time.current)
  end

  def self.refreshed_at_for(view_name)
    find_by(view_name: view_name)&.refreshed_at
  end
end
