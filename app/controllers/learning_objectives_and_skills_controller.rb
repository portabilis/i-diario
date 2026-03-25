class LearningObjectivesAndSkillsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @learning_objectives_and_skills = apply_scopes(LearningObjectivesAndSkill.ordered)

    group_children_education = GeneralConfiguration.current.group_children_education

    @grades = if group_children_education
      GroupChildEducations.to_select + ElementaryEducations.to_select[1..-1] +
        AdultAndYouthEducations.to_select[1..-1]
    else
      ChildEducations.to_select + ElementaryEducations.to_select[1..-1] +
        AdultAndYouthEducations.to_select[1..-1]
    end

    authorize @learning_objectives_and_skills
  end

  def new
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new

    authorize @learning_objectives_and_skill
  end

  def create
    @learning_objectives_and_skill = LearningObjectivesAndSkill.new(learning_objectives_and_skills_params)

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.save
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      @grades = ListGradesByStepBuilder.call(
        @learning_objectives_and_skill.step
      ).to_json
      render :new
    end
  end

  def edit
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    @grades = ListGradesByStepBuilder.call(
      @learning_objectives_and_skill.step
    ).to_json

    authorize @learning_objectives_and_skill
  end

  def update
    @learning_objectives_and_skill = LearningObjectivesAndSkill.find(params[:id])

    authorize @learning_objectives_and_skill

    if @learning_objectives_and_skill.update(learning_objectives_and_skills_params)
      respond_with @learning_objectives_and_skill, location: learning_objectives_and_skills_path
    else
      @grades = ListGradesByStepBuilder.call(
        @learning_objectives_and_skill.step
      ).to_json

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
        id: skill.id,
        description: "(#{skill.code}) #{skill.description}"
      }
    end

    respond_with(contents: @contents)
  end

  def fetch_grades
    return if params[:step].blank?

    render json: ListGradesByStepBuilder.call(params[:step], false)
  end

  def import
    authorize LearningObjectivesAndSkill, :import?
  end

  def validate_csv
    authorize LearningObjectivesAndSkill, :import?

    @selected_step = params[:step]
    @selected_import_mode = params[:import_mode]

    unless LearningObjectivesAndSkillsCsvParser::VALID_STEPS.include?(@selected_step)
      flash[:error] = t('learning_objectives_and_skills.validate_csv.step_required')
      return render :import
    end

    unless %w[add_new replace].include?(@selected_import_mode)
      flash[:error] = t('learning_objectives_and_skills.validate_csv.mode_required')
      return render :import
    end

    unless params[:file].present?
      flash[:error] = t('learning_objectives_and_skills.validate_csv.file_required')
      return render :import
    end

    parser = LearningObjectivesAndSkillsCsvParser.new(params[:file].tempfile, step: @selected_step)
    result = parser.parse

    @records = result.records
    @parse_errors = result.errors
    @import_mode = @selected_import_mode

    @grades_summary = build_grades_summary(@records, @selected_step) if @records.any?

    cache_key = "csv_import_#{current_user.id}_#{SecureRandom.hex(8)}"
    Rails.cache.write(cache_key, {
      records: @records,
      step: @selected_step,
      import_mode: @import_mode
    }, expires_in: 30.minutes)
    @cache_key = cache_key

    render :import
  end

  def confirm_import
    authorize LearningObjectivesAndSkill, :import?

    cached = Rails.cache.read(params[:cache_key])

    unless cached
      flash[:error] = t('learning_objectives_and_skills.confirm_import.session_expired')
      return redirect_to import_learning_objectives_and_skills_path
    end

    import_mode = params[:import_mode] || cached[:import_mode]
    grades = cached[:records].flat_map { |r| r[:grades] }.uniq
    modes_by_grade = grades.each_with_object({}) { |grade, h| h[grade] = import_mode }

    importer = LearningObjectivesAndSkillsCsvImporter.new(
      records: cached[:records],
      step: cached[:step],
      modes_by_grade: modes_by_grade
    )

    if importer.import
      Rails.cache.delete(params[:cache_key])
      flash[:success] = t(
        'learning_objectives_and_skills.confirm_import.success',
        imported: importer.imported_count,
        removed: importer.removed_count
      )
      redirect_to learning_objectives_and_skills_path
    else
      flash.now[:error] = t(
        'learning_objectives_and_skills.confirm_import.error_with_details',
        count: importer.errors.size
      )
      @import_errors = importer.errors
      @selected_step = cached[:step]
      @import_mode = import_mode
      @records = cached[:records]
      @grades_summary = build_grades_summary(@records, @selected_step)
      @cache_key = params[:cache_key]
      render :import
    end
  end

  private

  def build_grades_summary(records, step)
    csv_counts = Hash.new(0)
    csv_codes_by_grade = Hash.new { |h, k| h[k] = [] }

    records.each do |record|
      record[:grades].each do |grade|
        csv_counts[grade] += 1
        csv_codes_by_grade[grade] << record[:code]
      end
    end

    grade_order = LearningObjectivesAndSkillsCsvMappings::GRADES_BY_STEP[step] || []

    csv_counts.map do |grade, csv_count|
      existing_scope = LearningObjectivesAndSkill
                       .where(step: step)
                       .where('? = ANY(grades)', grade)

      existing_count = existing_scope.count

      conflicting_codes = existing_scope
                          .where(code: csv_codes_by_grade[grade])
                          .pluck(:code)

      {
        grade: grade,
        grade_label: grade_label_for(grade, step),
        csv_count: csv_count,
        existing_count: existing_count,
        conflicting_codes: conflicting_codes
      }
    end.sort_by { |g| grade_order.index(g[:grade]) || Float::INFINITY }
  end

  def grade_label_for(grade, step)
    klass = case step
            when 'elementary_school' then ElementaryEducations
            when 'child_school'
              if GeneralConfiguration.current.group_children_education
                GroupChildEducations
              else
                ChildEducations
              end
            when 'adult_and_youth_education' then AdultAndYouthEducations
    end
    klass&.t(grade) || grade.humanize
  rescue StandardError
    grade.humanize
  end

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

    return parameters if parameters[:step].blank?

    parameters[:grades] = params.require(:learning_objectives_and_skill)[:grades].split(',')
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
