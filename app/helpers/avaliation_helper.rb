module AvaliationHelper

  def show_avaliation_weight
    if @avaliation.test_setting.try(:arithmetic?)
      { class: 'hidden' }
    else
      {}
    end
  end

end
