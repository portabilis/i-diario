class TeacherProfilesOptionsGenerator
  def initialize(user)
    @user = user
  end

  def run!
    @indentation = 0
    @options = []
    teacher = @user.teacher

    profiles = teacher.teacher_profiles.includes(:classroom, :discipline, :unity)

    years = profiles.group_by(&:year).select { |year, _| available_years(profiles).include?(year) }

    each_profile(years) do |year, profiles_by_year|
      write_main_option(name_value: year.to_s) if years.size > 1

      each_profile(profiles_by_year.group_by(&:unity)) do |unity, profiles_by_unity|
        write_main_option(name_value: unity.name)

        each_profile(profiles_by_unity.group_by(&:classroom)) do |classroom, profiles_by_classroom|
          write_main_option(name_value: classroom.description)

          each_profile(profiles_by_classroom) do |profile|
            write_option(profile, unity, classroom, (year if years.size > 1))
          end
        end
      end
    end

    @options
  end

  private

  def write_main_option(options)
    css = "margin-left:#{@indentation * 10}px; font-weight: bold;"

    label = "<span style='#{css}'>#{options[:name_value]}</span>"

    @options << OpenStruct.new(id: options[:id], name: label)

    @indentation += 1
  end

  def write_option(profile, unity, classroom, year)
    text = ''
    text << "#{year} > " if year
    text << "#{unity.name} > "
    text << "#{classroom.description} > "
    text << profile.discipline.description

    css = "margin-left:#{@indentation * 10}px;"

    label = "<span style='#{css}'>#{profile.discipline.description}</span>"

    @options << OpenStruct.new(id: profile.id, name: label, text: text)
  end

  def each_profile(grouped_profiles)
    grouped_profiles.each do |group, profiles|
      yield(group, profiles)
    end

    @indentation -= 1
  end

  def available_years(profiles)
    @available_years ||=
      begin
        unity_ids = profiles.pluck(:unity_id).uniq

        unity_ids.map { |unity_id|
          available_years = @user.available_years(nil, unity_id)
          available_years.map { |year| year[:id] }
        }.flatten.uniq
      end
  end
end
