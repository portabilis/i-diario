class BackupFile
  class TeacherDisciplineClassrooms < Base
    def filename
      "professor_disciplina_turma.csv"
    end

    protected

    def query
      TeacherDisciplineClassroom
    end
  end
end
