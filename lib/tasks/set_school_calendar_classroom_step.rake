namespace :entity do
  desc "Set School Calendar Classroom Step"
  task set_school_calendar_classroom_step: :environment do
    school_calendar_classroom_step_setter = SchoolCalendarClassroomStepSetter.new(ENV)

    school_calendar_classroom_step_setter.set

    puts school_calendar_classroom_step_setter.status
  end
end
