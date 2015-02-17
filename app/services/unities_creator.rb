class UnitiesCreator
  def self.create!(unities)
    new(unities).create!
  end

  def initialize(unities)
    self.unities = unities
  end

  def create!
    begin
      selected_unities.each do |unity_params|
        required_params = unity_params.permit(
          :name, :phone, :email, :responsible, :api_code, :unit_type, :active,
          :address_attributes => [
            :id, :zip_code, :street, :number, :complement, :neighborhood, :city,
            :state, :country, :latitude, :longitude, :_destroy
          ]
        )

        unity = Unity.new(required_params)
        unity.api = true
        unity.author = author
        unity.save(validate: false)
      end
    rescue
      return false
    end
  end

  protected

  attr_accessor :unities

  def selected_unities
    unities.select { |u| u["api_code"].present? }
  end

  def author
    @user ||= User.admin.first
  end
end
