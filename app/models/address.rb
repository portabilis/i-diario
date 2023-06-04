class Address < ApplicationRecord
  acts_as_copy_target

  audited associated_with: :source, except: [:source_id, :source_type, :latitude, :longitude]

  has_enumeration_for :state, with: States

  belongs_to :source, polymorphic: true

  validates :zip_code, mask: { with: "99999-999", message: :incorrect_format }, allow_blank: true

  # TODO: Precisamos adicionar este vinculo
  def country
    "Brasil"
  end

  def to_s
    address = []

    address.push(street) if street.present?
    address.push(number) if number.present?
    address.push(neighborhood) if neighborhood.present?
    address.push("CEP: #{zip_code}") if zip_code.present?
    address.push(city) if city.present?
    address.push(state.upcase) if state.present?

    address.join(", ")
  end
end
