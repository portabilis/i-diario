class Content < ApplicationRecord
  include Audit

  audited
  has_associated_audits

  acts_as_copy_target

  has_many :teaching_plans, dependent: :restrict_with_error
  has_many :lesson_plans, dependent: :restrict_with_error
  has_many :content_records, dependent: :restrict_with_error
  has_and_belongs_to_many :content_records

  attr_accessor :is_editable

  validates :description, presence: true

  scope :by_description, lambda { |description|
    sanitized_terms = description.gsub(/[^a-zA-Z0-9\u00C0-\u024F\s]/, '').strip.split(/\s+/)
    prefix_query = sanitized_terms.map { |term| "#{term}:*" }.join(' & ')

    select("contents.*, ts_rank_cd(contents.document_tokens, to_tsquery('portuguese', #{sanitize(prefix_query)})) as rank").
    where("contents.document_tokens @@ to_tsquery('portuguese', ?)", prefix_query).
    order("rank desc")
  }

  scope :start_with_description, lambda { |description|
    where("description ILIKE ?", "#{description.upcase}%").
      order(created_at: :desc)
  }

  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :order_by_id, -> { order(id: :asc) }
  scope :find_and_order_by_id_sequence, lambda { |ids|
    joins("join unnest('{#{ids.join(',')}}'::int[]) WITH ORDINALITY t(id, ord) USING (id)").order('t.ord')
  }

  scope :by_teacher_id, lambda { |teacher_id|
    where(
      "contents.id IN (" \
        "SELECT crc.content_id FROM content_records_contents crc " \
        "INNER JOIN content_records cr ON cr.id = crc.content_record_id " \
        "WHERE cr.teacher_id = :teacher_id " \
        "UNION " \
        "SELECT ctp.content_id FROM contents_teaching_plans ctp " \
        "INNER JOIN teaching_plans tp ON tp.id = ctp.teaching_plan_id " \
        "WHERE tp.teacher_id = :teacher_id " \
        "UNION " \
        "SELECT clp.content_id FROM contents_lesson_plans clp " \
        "INNER JOIN lesson_plans lp ON lp.id = clp.lesson_plan_id " \
        "WHERE lp.teacher_id = :teacher_id" \
      ")",
      teacher_id: teacher_id
    )
  }

  after_save :update_description_token

  MAX_RETRIES = 3

  # Com bang: levanta ActiveRecord::RecordInvalid se a validação falhar (usado nos controllers web)
  def self.find_or_create_by_description!(description)
    retries = 0

    begin
      find_or_create_by!(description: description)
    rescue ActiveRecord::RecordNotUnique
      retries += 1
      retry if retries < MAX_RETRIES

      raise
    end
  end

  # Sem bang: retorna nil em caso de falha (usado na API v2 para não quebrar o sync do app mobile)
  def self.find_or_create_by_description(description)
    retries = 0

    begin
      find_or_create_by(description: description)
    rescue ActiveRecord::RecordNotUnique
      retries += 1
      retry if retries < MAX_RETRIES

      raise
    end
  end

  def to_s
    description
  end

  private

  def update_description_token
    Content.where(id: id).update_all("document_tokens = to_tsvector('portuguese', description)")
  end
end
