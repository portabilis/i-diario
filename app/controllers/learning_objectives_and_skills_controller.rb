class LearningObjectivesAndSkillsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @learning_objectives_and_skills = apply_scopes(LearningObjectivesAndSkill.ordered)

    authorize @learning_objectives_and_skills
  end

  def new
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new

    @grades = nil

    authorize @learning_objectives_and_skill
  end

  def create
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new(learning_objectives_and_skills_params)

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.save
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      render :new
    end
  end

  def edit
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    if @learning_objectives_and_skill.adult_and_youth_education?
      @grades = AdultAndYouthEducations.to_select.to_json
    else
      @grades = ElementaryEducations.to_select.to_json
    end

    authorize @learning_objectives_and_skill
  end

  def update
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.update(learning_objectives_and_skills_params)
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      render :edit
    end
  end

  def destroy
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill

    @learning_objectives_and_skill.destroy

    respond_with(
      @learning_objectives_and_skill,
      location: learning_objectives_and_skills_path,
      alert: @learning_objectives_and_skill.errors.to_a
    )
  end

  def history
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find params[:id]

    authorize @learning_objectives_and_skill

    respond_with @learning_objectives_and_skill
  end

  def contents
    @contents = []

    query = LearningObjectivesAndSkill.ordered
    query = search_query('experience_fields', query) if params[:experience_fields].present?
    query = search_query('disciplines', query) if params[:disciplines].present?
    query = search_query('group_child_schools', query) if params[:group_child_schools].present?

    query.each do |skill|
      @contents << {
        description: "(#{skill.code}) #{skill.description}"
      }
    end

    respond_with(contents: @contents)
  end

  def fetch_grades
    return if params[:step].blank?

    grades = case params[:step]
             when 'adult_and_youth_education'
               AdultAndYouthEducations.to_select(false)
             when 'elementary_school'
               ElementaryEducations.to_select(false)
             end

    render json: grades
  end

  private

  def learning_objectives_and_skills_params
    parameters = params.require(:learning_objectives_and_skill).permit(
      :code,
      :description,
      :step,
      :field_of_experience,
      :discipline,
      :thematic_unit,
      :grades
    )

    child_educations = params.require(:learning_objectives_and_skill)[:child_educations]
    elementary_educations = params.require(:learning_objectives_and_skill)[:elementary_educations]

    parameters[:grades] = elementary_educations.split(',') + child_educations.split(',')
    parameters
  end

  def grades_query
    <<-SQL
      AND grades @> ARRAY[?]::varchar[])
    SQL
  end

  def disciplines_query
    <<-SQL
      (discipline = ?
    SQL
  end

  def field_of_experience_query
    <<-SQL
      (field_of_experience = ?
    SQL
  end

  def search_query(type, query)
    query_builder = ''
    params_builder = []

    (params[type] || []).each do |index, value|
      query_builder += ' OR ' if index.to_i > 0
      query_builder += type == 'disciplines' ? disciplines_query : field_of_experience_query
      query_builder += value[:grades].present? ? grades_query : ')'
      params_builder << value[:type]
      params_builder << value[:grades] if value[:grades].present?
    end

    query.where(query_builder, *params_builder)
  end
end
