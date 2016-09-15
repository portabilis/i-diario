class SchoolCalendarClassroom < ActiveRecord::Base
  belongs_to :school_calendar
  belongs_to :classroom

  has_many :classroom_steps, -> { order(:start_at) }, class_name: 'SchoolCalendarClassroomStep', dependent: :destroy

  accepts_nested_attributes_for :classroom_steps, reject_if: :all_blank, allow_destroy: true
end
