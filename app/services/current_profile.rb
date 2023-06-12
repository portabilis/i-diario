class CurrentProfile
  ROLE_JSON = {
    only: [:id],
    methods: [:name, :can_change_school_year, :role_access_level, :unity_id]
  }
  UNITY_JSON = { only: [:id, :name] }
  CLASSROOM_JSON = { only: [:id, :description] }
  TEACHER_JSON = { only: [:id, :name] }

  attr_accessor :user, :user_role, :unity, :school_year, :classroom, :teacher, :discipline

  def initialize(user, options = {})
    options = options.with_indifferent_access

    self.user = user
    self.school_year = options[:by_school_year] || options[:school_year] || user.current_school_year
    self.user_role = initial_value(options, UserRole)
    self.unity = initial_value(options, Unity)
    self.classroom = initial_value(options, Classroom)
    self.teacher = initial_value(options, Teacher)
    self.discipline = initial_value(options, Discipline)
  end

  def user_role_as_json
    user_role.as_json(ROLE_JSON)
  end

  def user_roles
    cache 'user_roles' do
      user.user_roles.to_a
    end
  end

  def user_roles_as_json
    user_roles.as_json(ROLE_JSON)
  end

  def unity_as_json
    unity.as_json(UNITY_JSON)
  end

  def unities_as_json
    unities.as_json(UNITY_JSON)
  end

  def unities
    cache ['unities', user_role&.role_administrator?, user_role&.id, unity&.id] do
      return Unity.ordered if user_role&.role_administrator?

      [unity].compact
    end
  end

  def school_year_as_json(year = school_year)
    return unless year

    { id: year, name: year }
  end

  def school_years_as_json
    cache ['school_years_as_json', unity&.id, user_role&.can_change_school_year?] do
      return [] if unity.blank? || user_role.blank?

      years = YearsFromUnityFetcher.new(unity.id, !user_role.can_change_school_year?).fetch
      years.map { |year| school_year_as_json(year) }
    end
  end

  def classroom_as_json
    classroom.as_json(CLASSROOM_JSON)
  end

  def classrooms_as_json
    classrooms.as_json(CLASSROOM_JSON)
  end

  def classrooms
    cache ['classrooms', unity&.id, teacher&.id, school_year, user_role&.role&.teacher?] do
      return Classroom.none if unity.blank?

      classrooms = Classroom.by_unity(unity).ordered
      if user_role&.role&.teacher? && teacher.present?
        classrooms = classrooms.by_teacher_id(teacher).ordered
      end
      classrooms = classrooms.by_year(school_year) if school_year
      classrooms.to_a
    end
  end

  def teacher_as_json
    teacher.as_json(TEACHER_JSON)
  end

  def teachers_as_json
    teachers.as_json(TEACHER_JSON)
  end

  def teachers
    cache ['teachers', unity&.id, classroom&.id, school_year, user_role&.role&.teacher?, user.teacher_id] do
      return Teacher.none if unity.blank? || classroom.blank?
      return Teacher.where(id: user.teacher_id) if user_role&.role&.teacher?

      teachers_ids = TeacherDisciplineClassroom.where(classroom_id: classroom.id).distinct.pluck(:teacher_id)
      teachers = Teacher.where(id: teachers_ids).distinct.order_by_name
      teachers.to_a
    end
  end

  def discipline_as_json
    return unless discipline

    { id: discipline.id, discipline_id: discipline.id, description: discipline.to_s }
  end

  def disciplines_as_json
    disciplines.as_json
  end

  def last_allocation
    Rails.cache.fetch("last_teacher_discipline_classroom-#{classroom&.id}-#{teacher&.id}", expires_in: 1.day) do
      return TeacherDisciplineClassroom.none unless classroom && teacher

      TeacherDisciplineClassroom.where(classroom_id: classroom.id, teacher_id: teacher.id).last&.cache_key
    end
  end

  def disciplines
    cache ['disciplines', classroom&.id, teacher&.id, last_allocation] do
      return Discipline.none unless classroom && teacher

      Discipline.not_descriptor
                .by_teacher_and_classroom(teacher.id, classroom.id)
                .grouped_by_knowledge_area
                .to_a
    end
  end

  def teacher_profiles_as_json
    teacher_profiles.as_json
  end

  def teacher_profiles
    cache ['teacher_profiles', GeneralConfiguration.current.grouped_teacher_profile?, unity&.id, school_year] do
      return [] unless GeneralConfiguration.current.grouped_teacher_profile?
      return [] if user.teacher_id.blank?

      teacher_profiles = GroupedDiscipline.by_teacher_unity_and_year(user.teacher_id, unity&.id, school_year).to_a
      teacher_profiles = [] if teacher_profiles.size >= 20
      teacher_profiles
    end
  end

  def teacher_profile_as_json
    return unless classroom && discipline

    {
      uuid: "#{classroom.id}-#{discipline.id}",
      classroom_description: classroom.to_s,
      classroom_id: classroom.id,
      description: discipline.to_s,
      discipline_id: discipline.id,
      group_descriptors: user.current_knowledge_area&.group_descriptors,
      knowledge_area_id: user.current_knowledge_area_id
    }
  end

  private

  def initial_value(options, model)
    underscored_model = model.to_s.underscore
    underscored_model_id = "by_#{underscored_model}_id"
    current_method_for_user = "current_#{underscored_model}"

    value = options[underscored_model]
    value ||= model.find(options[underscored_model_id]) if options[underscored_model_id]
    value || user.send(current_method_for_user)
  end

  def cache(key_complements)
    Rails.cache.fetch cache_key_to_user + Array(key_complements), expires_in: 10.minutes do
      yield
    end
  end

  def cache_key_to_user
    ['CurrentProfile', Entity.current.id, user.id]
  end
end
