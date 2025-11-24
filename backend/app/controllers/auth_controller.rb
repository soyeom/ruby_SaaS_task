class AuthController < ApplicationController
  # POST /signup
  # ユーザー新規登録
  def signup
    login_id      = params[:login_id]
    password      = params[:password]
    password_conf = params[:password_conf]

    # 必須項目チェック
    if login_id.blank? || password.blank? || password_conf.blank?
      return render json: { error: "login_id, password, password_conf は必須です。" },
                    status: :bad_request
    end

    # ユーザー作成（パスワード確認込み）
    user = User.new(
      login_id: login_id,
      password: password,
      password_confirmation: password_conf
    )

    # 保存失敗時の処理
    unless user.save
      return render json: {
        error: "ユーザー登録に失敗しました。",
        details: user.errors.full_messages
      }, status: :unprocessable_entity
    end

    # 登録成功
    render json: {
      message: "ユーザー登録が完了しました。",
      user: {
        id: user.id,
        login_id: user.login_id
      }
    }, status: :created
  end

  # POST /login
  # ログイン
  def login
    login_id = params[:login_id]
    password = params[:password]

    # 必須項目チェック
    if login_id.blank? || password.blank?
      return render json: { error: "login_id と password は必須です。" },
                    status: :bad_request
    end

    user = User.find_by(login_id: login_id)

    # 認証処理
    if user&.authenticate(password)
      session[:user_id] = user.id

      render json: {
        message: "ログインに成功しました。",
        user: {
          id: user.id,
          login_id: user.login_id
        }
      }, status: :ok
    else
      render json: {
        error: "ログインIDまたはパスワードが正しくありません。"
      }, status: :unauthorized
    end
  end

  # DELETE /logout
  # ログアウト
  def logout
    session.delete(:user_id)

    render json: {
      message: "ログアウトしました。"
    }, status: :ok
  end
end