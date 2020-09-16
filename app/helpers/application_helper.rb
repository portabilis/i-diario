module ApplicationHelper
  include ActiveSupport::Inflector

  PROFILE_DEFAULT_PICTURE_PATH = '/assets/profile-default.jpg'.freeze

  def unread_notifications_count
    @unread_notifications_count ||= current_user.unread_notifications.count
  end

  def last_system_notifications
    @last_system_notifications ||= current_user.system_notifications.limit(10).ordered
  end

  def system_notification_path(notification)
    SystemNotificationRouter.path(notification)
  end

  def unities
    @unities ||= Unity.ordered
  end

  def resource
    instance_variable_get("@#{controller_name.singularize}")
  end

  def tagfy(value)
    transliterate(value).tr(' ', '_').underscore
  end

  def breadcrumbs
    Navigation.draw_breadcrumbs(controller_name, self)
  end

  def menus
    key = [
      'Menus',
      controller_name,
      current_user.current_user_role&.role&.cache_key || current_user.cache_key,
      Translation.cache_key
    ]

    Rails.cache.fetch(key, expires_in: 1.day) do
      Navigation.draw_menus(controller_name, current_user)
    end
  end

  def shortcuts
    key = [
      'HomeShortcuts',
      current_user.current_user_role&.role&.cache_key || current_user&.cache_key,
      Translation.cache_key
    ]

    Rails.cache.fetch(key, expires_in: 1.day) do
      Navigation.draw_shortcuts(current_user)
    end
  end

  def title
    Navigation.draw_title(controller_name, false, self)
  end

  def title_with_icon
    Navigation.draw_title(controller_name, true, self)
  end

  def simple_form_for(object, *args, &block)
    options = args.extract_options!
    options[:builder] ||= Portabilis::FormBuilder

    super object, *(args << options), &block
  end

  def profile_picture_tag(user, profile_picture_html_options = {})
    user_avatar_url = user_avatar_url(user)

    return unless user_avatar_url

    image_tag(user_avatar_url, profile_picture_html_options.merge(onerror: on_error_img, alt: ''))
  end

  def user_avatar_url(user)
    Rails.cache.fetch [:user_avatar_url, cache_key_to_user], expires_in: 1.day do
      user.profile_picture&.url ||
        IeducarAvatarAuth.new(user.student&.avatar_url.to_s).generate_new_url.presence ||
        PROFILE_DEFAULT_PICTURE_PATH
    end
  end

  def on_error_img
    "this.error=null;this.src='#{PROFILE_DEFAULT_PICTURE_PATH}'"
  end

  def custom_date_format(date)
    if date == Time.zone.today
      t('date.today')
    elsif date == Time.zone.yesterday
      t('date.yesterday')
    elsif date.year == Time.zone.today.year
      l(date, format: :short)
    else
      l(date, format: :long)
    end
  end

  def filename(file)
    file.path.split('/').last
  end

  def t_boolean(value)
    value ? t('boolean.yes') : t('boolean.no')
  end

  def number_of_classes_elements(number_of_classes)
    elements = []
    (1..number_of_classes).each do |i|
      elements << { id: i, name: i, text: i }
    end
    elements.to_json
  end

  def decimal_input_mask(number_of_decimal_places)
    if number_of_decimal_places
      { data: { inputmask: "'digits': #{number_of_decimal_places}" } }
    else
      { data: { inputmask: "'digits': 0" } }
    end
  end

  def entity_copyright
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_copyright", expires_in: 1.day) do
      "© #{GeneralConfiguration.current.copyright_name} #{Time.zone.today.year}"
    end
  end

  def entity_website
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_website", expires_in: 1.day) do
      GeneralConfiguration.current.support_url
    end
  end

  def alert_by_entity(_entity_name)
    ''
  end

  def initial_value_for_select2_remote(id, description)
    '{"id": ' + id.to_s + ', "description": "' + description.tr("\n", ' ') + '"}'
  end

  def link_to_if_and_else(*args, &block)
    condition = args.shift
    content = capture(&block)

    if condition
      link_to(*args) do
        content
      end
    else
      content
    end
  end

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)

    yield(presenter) if block_given?
  end

  def default_steps
    (Bimesters.to_select + Trimesters.to_select + Semesters.to_select + BimestersEja.to_select).uniq
  end

  def teacher_profiles_options
    cache_key = ['TeacherProfileList', current_entity.id, current_user.teacher&.cache_key]

    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      TeacherProfilesOptionsGenerator.new(current_user).run!
    end
  end

  def use_teacher_profile?
    current_user.can_use_teacher_profile? &&
      current_user.teacher &&
      current_user.teacher.teacher_profiles.present?
  end

  def current_user_available_disciplines
    return [] unless current_user_classroom && current_teacher

    cache_key = [
      'ApplicationHelper#current_user_available_disciplines',
      cache_key_to_user,
      current_user_classroom.try(:id),
      current_teacher.try(:id)
    ]

    @current_user_available_disciplines ||=
      Rails.cache.fetch cache_key, expires_in: 10.minutes do
        Discipline.by_teacher_id(current_teacher).by_classroom(current_user_classroom).ordered
      end
  end

  def current_user_available_knowledge_areas
    return [] unless current_user_classroom && current_teacher

    Discipline
      .by_teacher_and_classroom(current_teacher.id, current_user_classroom.id)
      .grouped_by_knowledge_area
      .as_json
  end

  def current_unities
    cache_key = [
      'ApplicationHelper#current_unities',
      cache_key_to_user,
      current_user.current_user_role.id
    ]

    @current_unities ||=
      Rails.cache.fetch cache_key, expires_in: 10.minutes do
        if current_user.current_user_role.try(:role_administrator?)
          Unity.ordered
        else
          [current_unity]
        end.compact
      end
  end

  def current_user_available_years
    return [] if current_unity.blank?

    @current_user_available_years ||= current_user.available_years(current_unity)
  end

  def current_user_available_teachers
    return [] if current_unity.blank? || current_user_classroom.blank?

    cache_key = [
      'ApplicationHelper#current_user_available_teachers',
      cache_key_to_user,
      current_user_classroom.try(:id)
    ]

    @current_user_available_teachers ||=
      Rails.cache.fetch cache_key, expires_in: 10.minutes do
        teachers = Teacher.by_unity_id(current_unity)
                          .by_classroom(current_user_classroom)
                          .order_by_name

        if current_school_calendar.try(:year)
          teachers.by_year(current_school_calendar.try(:year))
        else
          teachers
        end
      end
  end

  def current_user_available_classrooms
    return [] if current_unity.blank?

    cache_key = [
      'ApplicationHelper#current_user_available_classrooms',
      cache_key_to_user,
      current_teacher.try(:id),
      current_school_calendar.try(:year),
      current_user.current_user_role.id
    ]

    @current_user_available_classrooms ||=
      Rails.cache.fetch cache_key, expires_in: 10.minutes do
        classrooms = if current_teacher.present? && current_user.teacher?
                       Classroom.by_unity_and_teacher(current_unity, current_teacher).ordered
                     else
                       Classroom.by_unity(current_unity).ordered
                     end

        if current_school_calendar.try(:year)
          classrooms.by_year(current_school_calendar.try(:year))
        else
          classrooms
        end
      end
  end

  def back_link(name, path)
    content_for :back_link do
      back_link_tag(name, path)
    end
  end

  def back_link_tag(name, path)
    link_to path, class: 'back-link' do
      raw <<-HTML
        <i class="icon-append fa fa-angle-left"></i>
        #{name}
      HTML
    end
  end

  def include_recaptcha_js
    return '' if recaptcha_site_key.blank?

    raw %Q{
      <script src="https://www.google.com/recaptcha/api.js?render=#{recaptcha_site_key}"></script>
    }
  end

  def recaptcha_execute
    return '' if recaptcha_site_key.blank?

    id = "recaptcha_token_#{SecureRandom.hex(10)}"

    raw %Q{
      <input name="recaptcha_token" type="hidden" id="#{id}"/>
      <script>
        grecaptcha.ready(function() {
          grecaptcha.execute('#{recaptcha_site_key}').then(function(token) {
            document.getElementById("#{id}").value = token;
          });
        });
      </script>
    }
  end

  def window_state
    {
      current_role: current_user.current_user_role.as_json(
        only: [:id],
        methods: [:name, :can_change_school_year, :role_access_level, :unity_id]
      ),
      available_roles: current_user.user_roles.as_json(
        only: [:id],
        methods: [:name, :can_change_school_year, :role_access_level, :unity_id]
      ),
      current_unity: current_user.current_unity.as_json(only: [:id, :name]),
      available_unities: current_unities.as_json(only: [:id, :name]),
      current_school_year: (
        if current_user.current_school_year
          {
            id: current_user.current_school_year,
            name: current_user.current_school_year
          }
        end
      ),
      available_school_years: current_user_available_years,
      current_classroom: current_user.current_classroom.as_json(only: [:id, :description]),
      available_classrooms: current_user_available_classrooms.as_json(only: [:id, :description]),
      current_teacher: current_user.current_teacher.as_json(only: [:id, :name]),
      available_teachers: current_user_available_teachers.as_json(only: [:id, :name]),
      current_discipline: current_user_available_knowledge_areas.find { |discipline|
        discipline['id'] == current_user.current_discipline_id
      }.as_json,
      available_disciplines: current_user_available_knowledge_areas.as_json,
      teacher_id: current_user.teacher_id
    }
  end

  private

  def cache_key_to_user
    [current_entity.id, current_user.id]
  end

  def recaptcha_site_key
    @recaptcha_site_key ||= Rails.application.secrets.recaptcha_site_key
  end
end
