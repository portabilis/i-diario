

t = StudentEnrollmentClassroom.where(api_code: '248039'); nil
t = t.where(api_code: '27908'); nil
StudentEnrollmentClassroom.where(t.where_values.join(' OR '))

StudentEnrollmentClassroom.where(t.where_values.inject(:or))

