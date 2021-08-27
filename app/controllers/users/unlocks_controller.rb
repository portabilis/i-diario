class Users::UnlocksController < Devise::UnlocksController

  def show
    super
    self.resource.update_columns(status: "active") if self.resource.persisted?
  end
end
