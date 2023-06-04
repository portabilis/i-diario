class SetNullInDuplicatedLoginsByCpfAndEmail < ActiveRecord::Migration[4.2]
  def change
    users = User.where("COALESCE(login, '') <> ''").order("status = 'actived'")

    users.each do |user|
      next unless CPF.valid?(user.login) ||
                  user.login =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i ||
                  exists_login?(user.login, user.id)

      user.without_auditing do
        user.update(login: nil)
      end
    end
  end

  def exists_login?(login, id)
    User.where.not(id: id)
        .where("users.login = ? AND COALESCE(users.login, '') <> ''", login)
        .exists?
  end
end
