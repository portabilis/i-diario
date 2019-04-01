class OldStepsConceptualValuesController < ApplicationController
  respond_to :json

  def index
    classroom = Classroom.find(params[:classroom_id])
    student = Student.find(params[:student_id])
    step = StepsFetcher.new(classroom).step_by_id(params[:step_id])

    render(json: OldStepsConceptualValuesFetcher.new(classroom, student, step).fetch)
  end
end
