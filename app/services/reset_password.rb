class ResetPassword
  attr_reader :user, :status

  def initialize(options)
    @user = options['USER']
  end

  def update
    return success if params? && update_user

    error
  end

  private

  def params?
    user
  end

  def update_user
    new_password = SecureRandom.hex(8)
    ActiveRecord::Base.transaction do
      Entity.all.each do |e|
        e.using_connection do
          @user = User.find_by(login: user)
          next if @user.blank?

          @user.password = new_password
          @user.save!
        end
      end
      UserMailer.delay.reset_password(@user.login, @user.first_name, @user.email, new_password) if @user.exists?
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def success
    @status = 'Usuário atualizado com sucesso.'
  end

  def error
    @status = 'Não foi possível atualizar o usuário.'
  end
end
