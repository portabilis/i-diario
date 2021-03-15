class SchoolTermTypeStepsController < ApplicationController
  def steps
    return unless (school_term_type_id = params[:school_term_type_id])

    school_term_type_steps = SchoolTermTypeStep.where(school_term_type_id: school_term_type_id)
    school_term_type_steps = school_term_type_steps.map { |step| { id: step.id, description: step.to_s } }

    render json: school_term_type_steps
  end
end
