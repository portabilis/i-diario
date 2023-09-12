class Content < ApplicationRecord
  include Audit

  audited
  has_associated_audits

  acts_as_copy_target

  has_many :teaching_plans, dependent: :restrict_with_error
  has_many :lesson_plans, dependent: :restrict_with_error
  has_many :content_records, dependent: :restrict_with_error

  attr_accessor :is_editable

  validates :description, presence: true

  scope :by_description, lambda { |description|
    where("contents.document_tokens @@ plainto_tsquery('portuguese', ?)", description).
      order("ts_rank_cd(contents.document_tokens, plainto_tsquery('portuguese', #{self.sanitize(description)})) desc")
  }

  scope :start_with_description, lambda { |description|
    where("description LIKE ?", "#{description.upcase}%").
      order(created_at: :desc)
  }

  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :order_by_id, -> { order(id: :asc) }
  scope :find_and_order_by_id_sequence, lambda { |ids|
    joins("join unnest('{#{ids.join(',')}}'::int[]) WITH ORDINALITY t(id, ord) USING (id)").order('t.ord')
  }

  after_save :update_description_token

  def to_s
    description
  end

  private

  def update_description_token
    Content.where(id: id).update_all("document_tokens = to_tsvector('portuguese', description)")
  end
end
