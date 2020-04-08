# encoding: utf-8

module ApplicationHelper
  include ActiveSupport::Inflector

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
    Rails.cache.fetch(["Menus-#{current_entity.id}", current_user, controller_name]) do
      Navigation.draw_menus(controller_name, current_user)
    end
  end

  def shortcuts
    Rails.cache.fetch(["Home-Shortcuts-#{current_entity.id}", current_user]) do
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

  def gravatar_image_tag(email, size = '48', html_options = {})
    email = Digest::MD5.hexdigest(email.to_s)
    default_avatar = CGI.escape(
      'https://s3-sa-east-1.amazonaws.com/apps-core-images-test/uploads/avatar/avatar.jpg'
    )

    html_options['height'] = "#{size}px"
    html_options['width'] = "#{size}px"
    html_options['onerror'] = "this.error=null;this.src='/assets/profile-default.jpg'"

    image_tag(
      "https://www.gravatar.com/avatar/#{email}?size=#{size}&d=#{default_avatar}",
      html_options
    )
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
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_copyright", expires_in: 10.minutes) do
      "© #{GeneralConfiguration.current.copyright_name} #{Time.zone.today.year}"
    end
  end

  def entity_website
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_website", expires_in: 10.minutes) do
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

  def indentation_control(grouped_profiles, indentation)
    grouped_profiles.each do |group, profiles|
      yield(group, profiles)
    end

    indentation -= 1
  end

  def teacher_profiles_options
    Rails.cache.fetch(['TeacherProfileList', current_entity.id, current_user]) do
      list = []
      indentation = 0

      profiles = current_user.teacher_profiles.includes(:classroom, :discipline, :unity)

      years = profiles.group_by(&:year)

      indentation_control(years, indentation) do |year, profiles|
        if years.size > 1
          list << teacher_profile_option(name_value: year.to_s, bold: true, indentation: indentation)
        end

        indentation_control(profiles.group_by(&:unity), indentation) do |unity, profiles|
          list << teacher_profile_option(name_value: unity.name, bold: true, indentation: indentation)

          indentation_control(profiles.group_by(&:classroom), indentation) do |classroom, profiles|
            list << teacher_profile_option(name_value: classroom.description, bold: true, indentation: indentation)

            profiles.each do |profile|
              text = ''
              text << "#{year} > " if years.size > 1
              text << "#{unity.name} > "
              text << "#{classroom.description} > "
              text << profile.discipline.description

              list << teacher_profile_option(id: profile.id,
                                             name_value: profile.discipline.description,
                                             text: text,
                                             bold: false,
                                             indentation: indentation)
            end
          end
        end
      end

      list
    end
  end

  def teacher_profile_option(options)
    css = "margin-left:#{options[:indentation] * 10}px;"
    css << 'font-weight: bold;' if options[:bold]

    label = content_tag :span, style: css do
      options[:name_value]
    end

    OpenStruct.new(id: options[:id],
                   name: label,
                   text: options[:text])
  end
end
