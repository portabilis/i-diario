class StudentInFinalRecoverySerializer < StudentSerializer
  attributes :needed_score

  def needed_score    
    object.needed_score
  end
end
