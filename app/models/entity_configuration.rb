class EntityConfiguration < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_one :address, as: :source, inverse_of: :source

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  validates :cnpj, mask: { with: "99.999.999/9999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true

  mount_uploader :logo, EntityLogoUploader

  def self.current
    self.first.presence || new
  end
end
