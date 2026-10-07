class EntityConfiguration < ApplicationRecord
  LOGO_VARIANTS = %i[pdf web].freeze

  acts_as_copy_target

  audited except: [:logo]

  include Audit

  attr_accessor :update_request_remote_ip, :update_user_id

  has_one :address, as: :source, inverse_of: :source

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  before_validation :upcase_cnpj

  validates :cnpj, alphanumeric_cnpj: true, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true

  mount_uploader :logo, EntityLogoUploader

  after_update :create_logo_audit
  after_save :invalidate_logo_cache, if: :logo_changed?

  def self.current
    self.first.presence || new
  end

  # :pdf é o arquivo que Prawn e o gerador de PDF conseguem ler; :web é o WebP da tela.
  def cached_logo_data(variant = :pdf)
    return nil if logo.blank? || logo.url.blank?
    # Sem a rede corrente a chave não distingue tenant; lê direto do arquivo.
    return fetch_logo_data(variant) if Entity.current.nil?

    Rails.cache.fetch(logo_cache_key(variant), expires_in: 1.day) { fetch_logo_data(variant) }
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

  # O diretório do brasão não separa as redes e o arquivo legado guarda o nome enviado,
  # então outra rede pode apontar para o mesmo arquivo: só o otimizado, cujo nome é único,
  # é apagado na troca.
  def remove_previously_stored_logo
    previous_identifier = previous_changes.fetch('logo', []).first
    return unless EntityLogoUploader.optimized_identifier?(previous_identifier)

    super
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

  # Grava o CNPJ sempre em maiúsculas para consistência no banco/exibição
  # (o formato alfanumérico usa letras A-Z). A validação já é case-insensitive.
  def upcase_cnpj
    self.cnpj = cnpj.upcase if cnpj.present?
  end

  # O Rails.cache é um só para todas as redes e esta tabela tem uma linha por
  # banco, então o id é o mesmo em toda rede: a chave precisa da rede corrente,
  # senão redes com brasão de mesmo nome de arquivo recebem a imagem uma da outra.
  def logo_cache_key(variant, identifier = logo.identifier)
    "entity_logo_data:#{Entity.current.id}:#{id}:#{variant}:#{identifier}"
  end

  def fetch_logo_data(variant)
    file = variant == :web ? logo : logo.for_pdf
    image_data = file.read
    extension = File.extname(file.path.to_s).delete('.')
    content_type = Mime::Type.lookup_by_extension(extension).to_s

    { data: image_data, content_type: content_type }
  end

  def invalidate_logo_cache
    return if Entity.current.nil?

    old_identifier = logo_was&.identifier

    LOGO_VARIANTS.each do |variant|
      Rails.cache.delete(logo_cache_key(variant, old_identifier)) if old_identifier
      Rails.cache.delete(logo_cache_key(variant)) if logo.identifier
    end
  end
end
