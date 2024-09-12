module Api
  class ClassroomAttendanceService

    attr_accessor :classrooms_api_code, :start_at, :end_at, :year

    def initialize(classrooms_api_code, start_at, end_at, year)
      @classrooms_api_code = classrooms_api_code
      @start_at = start_at
      @end_at = end_at
      @year = year
    end

    def self.call(classrooms_api_code, start_at, end_at, year)
      new(classrooms_api_code, start_at, end_at, year).call
    end

    def call
      query_classrooms
      student_enrollment_classrooms = query_student_enrollment_classrooms
      frequencies = query_daily_frequencies

      build_classroom_information(student_enrollment_classrooms, frequencies)
    end

    private

    def query_classrooms
      @classrooms = Classroom
        .includes(classrooms_grades: { grade: :course })
        .where(api_code: classrooms_api_code.values)
        .by_year(year)
        .order(:api_code)
    end

    def build_classroom_information(student_enrollment_classrooms, daily_frequencies)
      @classrooms.map do |classroom|
        classroom_api_code = classroom.api_code
        classroom_name = classroom.description
        classroom_max_students = classroom.max_students
        enrollments_by_classroom_count = student_enrollment_classrooms[classroom_api_code] ||= {}
        frequencies = daily_frequencies[classroom_api_code] ||= {}

        teste = enrollments_by_classroom_count.map do |date_enrollments, enrollments_count|
          {
            date_enrollments => {
              frequencies: frequencies[date_enrollments] || 0,
              enrollments: enrollments_count[:enrollments]
            }
          }
        end.reduce(:merge)

        grades = build_grade_hashes(classroom)

        {
          classroom_id: classroom_api_code,
          classroom_name: classroom_name,
          classroom_max_students: classroom_max_students,
          grades: grades,
          attendance_and_enrollments: teste
        }
      end
    end

    def query_student_enrollment_classrooms
      counts = {}
      school_days = set_school_days

      student_enrollment_classrooms = StudentEnrollmentClassroom
        .includes(student_enrollment: :student)
        .by_classroom(@classrooms.pluck(:id))
        .by_date_range(start_at, end_at)
        .group_by(&:classroom_code)

      student_enrollment_classrooms.each do |classroom_code, enrollments|
        counts[classroom_code] ||= {}

        school_days.each do |day|
          counts[classroom_code][day] ||= { enrollments: 0 }

          enrollments.each do |enrollment|
            next unless enrollment.joined_at <= day && (enrollment.left_at.blank? || enrollment.left_at >= day)

            counts[classroom_code][day][:enrollments] += 1
          end
        end
      end

      counts
    end

    def query_daily_frequencies
      school_days_query = UnitySchoolDay
        .select(:school_day)
        .where(unity_id: @classrooms.first.unity_id)
        .where(school_day: start_at..end_at).to_sql

      daily_frequencies_query = DailyFrequency.select(:id, :frequency_date, :classroom_id)
        .where(classroom_id: @classrooms.pluck(:id)).to_sql

      query = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT
          COUNT(DISTINCT CONCAT(dfs.student_id::TEXT, '-', df.frequency_date::TEXT)) AS count,
          COUNT(DISTINCT CASE
            WHEN dfs.present and sec.id is not null
            THEN dfs.student_id::TEXT || '-' || df.frequency_date::TEXT
          END) AS presences,
          c.api_code AS classroom_api_code,
          df.frequency_date AS frequency_date
        FROM
          (#{school_days_query}) AS sd
        LEFT JOIN
          (#{daily_frequencies_query}) AS df ON df.frequency_date = sd.school_day
        LEFT JOIN
          classrooms c ON c.id = df.classroom_id AND c.discarded_at IS NULL
        LEFT JOIN
          daily_frequency_students dfs ON dfs.daily_frequency_id = df.id AND dfs.discarded_at IS NULL
        LEFT JOIN
          students s ON s.id = dfs.student_id AND s.discarded_at IS NULL
        LEFT JOIN
          student_enrollments se ON se.student_id = s.id AND se.discarded_at IS NULL
        LEFT JOIN
          student_enrollment_classrooms sec ON sec.student_enrollment_id = se.id AND sec.discarded_at IS NULL
        WHERE
          sec.joined_at::DATE <= sd.school_day and (sec.left_at = '' or sec.left_at::DATE >= sd.school_day)
          and sec.classroom_code = c.api_code
        GROUP BY
          c.api_code, df.frequency_date
      SQL

      results = query.each_with_object({}) do |record, hash|
        classroom_api_code = record['classroom_api_code']
        frequency_date = record['frequency_date']
        presences = record['presences']

        hash[classroom_api_code] ||= {}
        hash[classroom_api_code][frequency_date] = presences
      end
    end

    def build_grade_hashes(classroom)
      classroom.classrooms_grades.map do |classroom_grade|
        {
          id: classroom_grade.grade.api_code,
          name: classroom_grade.grade.description,
          course_id: classroom_grade.grade.course.api_code,
          course_name: classroom_grade.grade.course.description
        }
      end
    end

    def attendance_and_enrollment_data(frequencies, enrollments_by_classroom_count)
      enrollments_by_classroom_count.map do |date_enrollments, enrollments_count|
        {
          date_enrollments => {
            frequencies: frequencies[date_enrollments] || 0,
            enrollments: enrollments_count["count"]
          }
        }
      end.reduce(:merge)
    end

    def set_school_days
      UnitySchoolDay.where(unity_id: @classrooms.first.unity_id)
                    .where('school_day BETWEEN ? AND ?', start_at, end_at)
                    .map { |day| day.school_day.strftime('%Y-%m-%d') }
    end
  end
end
