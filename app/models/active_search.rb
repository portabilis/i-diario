class ActiveSearch < ActiveRecord::Base
  belongs_to :student_enrollment

  has_enumeration_for :status, with: ActiveSearchStatus, create_helpers: true
end
