namespace :send_exam_another_classroom do
  desc "Send exams from another classroom"
  task send: :environment do
    name = ENV['NAME']
    year = ENV['YEAR']
    id = ENV['ID']

    Entity.connect(name)

    entity_id = Entity.current.id

    teacher_discipline_classroom_all = TeacherDisciplineClassroom
      .by_year(year)
      .by_score_type([ScoreTypes::NUMERIC, nil])
      .order(:id)

    if id
      teacher_discipline_classroom_all = teacher_discipline_classroom_all.where('id > ?', id)
    end

    count = teacher_discipline_classroom_all.count

    puts "Vínculos entre professores, disciplinas e turmas: #{count}"

    teacher_discipline_classroom_all.each do |teacher_discipline_classroom|
      puts "Vínculo: #{teacher_discipline_classroom.id}"

      classroom = teacher_discipline_classroom.classroom
      teacher = teacher_discipline_classroom.teacher
      discipline = teacher_discipline_classroom.discipline

      next if classroom && classroom.unity_id == 38

      begin
        step = StepsFetcher.new(classroom).step(1)
      rescue
        next
      end

      # score_rounder = ScoreRounder.new(classroom, RoundedAvaliations::SCHOOL_TERM_RECOVERY)

      teacher_score_fetcher = ExamPoster::TeacherScoresFetcher.new(
        teacher,
        classroom,
        discipline,
        step
      )
      teacher_score_fetcher.fetch!

      student_scores = teacher_score_fetcher.scores

      student_scores.each do |student|
        # next if exempted_discipline(classroom, discipline.id, student.id)
        # next unless correct_score_type(student.uses_differentiated_exam_rule, classroom.exam_rule)

        #exempted_discipline_ids =
        #  ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)

        # next if exempted_discipline_ids.include?(discipline.id)

        # school_term_recovery = fetch_school_term_recovery_score(classroom, discipline, student.id)
        value = StudentAverageCalculator
          .new(student)
          .calculate(classroom, discipline, step)

        student_enrollment_classroom = StudentEnrollmentClassroom
          .by_student(student)
          .by_classroom(classroom)
          .active
          .ordered
          .last

        current_student_enrollment_classroom = student_enrollment_classroom
          .student_enrollment
          .student_enrollment_classrooms
          .active
          .last

        next if current_student_enrollment_classroom.blank?

        current_classroom = current_student_enrollment_classroom.classroom

        next if current_classroom.blank?
        next if classroom.id == current_classroom.id

        # puts "Turma anterior: #{current_student_enrollment_classroom.classroom}"

        if value
          # puts "Turma: #{classroom}"
          # puts "Professor: #{teacher}"
          # puts "Disciplina: #{discipline}"
          # puts "Aluno: #{student.name}"
          # puts "Nota: #{value}"
          # puts
          SendExamAnotherClassroom.perform_in 1.second, entity_id, current_classroom.api_code, student.api_code, discipline.api_code, value
        end

        # next unless school_term_recovery

        #if (recovery_value = score_rounder.round(school_term_recovery))
        #  scores[classroom.api_code][student.api_code][discipline.api_code]['recuperacao'] = recovery_value
        #end
      end
    end
  end
end
