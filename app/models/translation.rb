class Translation < ActiveRecord::Base
  CACHE_KEY = 'translations'.freeze

  audited

  has_enumeration_for :group, with: TranslationGroups
  has_enumeration_for :subgroup, with: TranslationSubgroups

  validates :key, presence: true
  validates :label, presence: true
  validates :group, presence: true
  validates :subgroup, presence: true
  validates :order, presence: true

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
end
