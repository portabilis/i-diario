class EntityConfiguration < ApplicationRecord
  acts_as_copy_target

  audited except: [:logo]

  include Audit

  attr_accessor :update_request_remote_ip, :update_user_id

  has_one :address, as: :source, inverse_of: :source

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  validates :cnpj, mask: { with: "99.999.999/9999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true

  mount_uploader :logo, EntityLogoUploader

  after_update :create_logo_audit
  after_save :invalidate_logo_cache, if: :logo_changed?

  def self.current
    self.first.presence || new
  end

  def cached_logo_data
    return nil if logo.blank? || logo.url.blank?

    Rails.cache.fetch(logo_cache_key, expires_in: 1.day) { fetch_logo_data }
  rescue StandardError => e
    Rails.logger.warn("Failed to cache logo: #{e.message}")
    nil
  end

  def cached_logo
    cached = cached_logo_data
    return nil unless cached

    StringIO.new(cached[:data])
  end

  def logo_base64_data_uri
    cached = cached_logo_data
    return nil unless cached

    "data:#{cached[:content_type]};base64,#{Base64.strict_encode64(cached[:data])}"
  end

  def create_logo_audit
    return unless logo_changed?

    changed_logo = logo_was&.file ? File.basename(logo_was.file.path) : nil

    audits.create!(
      action: 'update',
      audited_changes: { 'logo': [changed_logo, logo.filename] },
      remote_address: update_request_remote_ip,
      user_id: update_user_id
    )
  end

  private

  def logo_cache_key
    "entity_logo_data:#{id}:#{logo.identifier}"
  end

  def fetch_logo_data
    image_data = logo.read
    extension = File.extname(logo.identifier).delete('.')
    content_type = Mime::Type.lookup_by_extension(extension).to_s

    { data: image_data, content_type: content_type }
  end

  def invalidate_logo_cache
    old_identifier = logo_was&.identifier
    Rails.cache.delete("entity_logo_data:#{id}:#{old_identifier}") if old_identifier
    Rails.cache.delete("entity_logo_data:#{id}:#{logo.identifier}") if logo.identifier
  end
end
