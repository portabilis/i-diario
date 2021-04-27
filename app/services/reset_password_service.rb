class ResetPasswordService
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
      Entity.all.each do |entity|
        entity.using_connection do
          @user = User.find_by(login: user)
          next if @user.blank?

          @user.password = new_password
          @user.password_confirmation = new_password
          @user.save!
        end
      end
      UserMailer.delay.reset_password(@user.login, @user.first_name, @user.email, new_password) if @user
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def success
    @status = 'Senha atualizada com sucesso.'
  end

  def error
    @status = 'Não foi possível atualizar a senha.'
  end
end
