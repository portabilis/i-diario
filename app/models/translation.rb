class Translation < ActiveRecord::Base
  CACHE_KEY = 'translations'.freeze
  private_constant :CACHE_KEY

  audited

  has_enumeration_for :group, with: TranslationGroups
  has_enumeration_for :subgroup, with: TranslationSubgroups

  with_options presence: true do
    validates :key
    validates :label
    validates :group
    validates :subgroup
    validates :order
  end

  scope :ordered, -> { order(:order) }
  scope :order_min, -> { order(Arel::Nodes::Min.new([arel_table[:order]])) }
  scope :order_subgroups, -> { order(subgroup: :desc) }

  def self.groups
    group(:group)
      .order_min
      .select(:group)
      .map(&:group)
  end

  def self.subgroups(group)
    where(group: group)
      .group(:subgroup)
      .order_subgroups
      .select(:subgroup)
      .map(&:subgroup)
  end

  def self.cache_key
    "#{Entity.current_domain}-#{CACHE_KEY}-#{Translation.order(:updated_at).last&.updated_at}"
  end
end
