class RecoveryDiaryRecordStudent < ActiveRecord::Base
  belongs_to :recovery_diary_record
  belongs_to :student
end
