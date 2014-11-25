class Address < Portabilis::Model
  audited associated_with: :source

  has_enumeration_for :state, with: States

  belongs_to :source, polymorphic: true

  validates :source, :zip_code, :street, :number, :neighborhood, :city,
    :state, :country, presence: true
  validates :zip_code, mask: { with: "99999-999", message: :incorrect_format }, allow_blank: true
end
