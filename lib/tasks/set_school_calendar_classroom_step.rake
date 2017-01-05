namespace :entity do
  desc "Set School Calendar Classroom Step By Date"
  task set_school_calendar_classroom_step_by_date: :environment do
    school_calendar_classroom_step_setter_by_date = SchoolCalendarClassroomStepSetterByDate.new(ENV)

    school_calendar_classroom_step_setter_by_date.set

    puts school_calendar_classroom_step_setter_by_date.status
  end

  desc "Set School Calendar Classroom Step By Step"
  task set_school_calendar_classroom_step_by_step: :environment do |t|
    school_calendar_classroom_step_setter_by_step = SchoolCalendarClassroomStepSetterByStep.new(ENV)

    school_calendar_classroom_step_setter_by_step.set

    puts school_calendar_classroom_step_setter_by_step.status
  end
end
