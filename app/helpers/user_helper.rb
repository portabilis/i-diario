module UserHelper

  def user_status_label situation
    '' if situation.blank?

    case situation
    when UserStatus::PENDING
      'label label-default'
    when UserStatus::ACTIVE
      'label label-success'
    end
  end
end