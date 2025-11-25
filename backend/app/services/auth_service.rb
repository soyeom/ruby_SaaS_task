# app/services/auth_service.rb
class AuthService
  # ユーザー新規登録
  def self.signup(login_id:, password:, password_conf:)
    if login_id.blank? || password.blank? || password_conf.blank?
      return [:invalid, "login_id, password, password_conf は必須です。"]
    end

    user = User.new(
      login_id: login_id,
      password: password,
      password_confirmation: password_conf
    )

    if user.save
      [:ok, user]
    else
      [:validation_failed, user.errors.full_messages]
    end
  end

  # ログイン
  def self.login(login_id:, password:)
    if login_id.blank? || password.blank?
      return [:invalid, "login_id と password は必須です。"]
    end

    user = User.find_by(login_id: login_id)

    if user&.authenticate(password)
      [:ok, user]
    else
      [:unauthorized, "ログインIDまたはパスワードが正しくありません。"]
    end
  end
end
