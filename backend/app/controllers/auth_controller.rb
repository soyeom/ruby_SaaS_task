class AuthController < ApplicationController
  # POST /signup
  # ユーザー新規登録
  def signup
    status, payload = AuthService.signup(
      login_id:      params[:login_id],
      password:      params[:password],
      password_conf: params[:password_conf]
    )

    case status
    when :ok
      user = payload
      render json: {
        message: "ユーザー登録が完了しました。",
        user: {
          id:       user.id,
          login_id: user.login_id
        }
      }, status: :created

    when :invalid
      render json: {
        error: payload
      }, status: :bad_request

    when :validation_failed
      render json: {
        error:   "ユーザー登録に失敗しました。",
        details: payload
      }, status: :unprocessable_entity
    end
  end

  # POST /login
  # ログイン
  def login
    status, payload = AuthService.login(
      login_id: params[:login_id],
      password: params[:password]
    )

    case status
    when :ok
      user = payload
      session[:user_id] = user.id

      render json: {
        message: "ログインに成功しました。",
        user: {
          id:       user.id,
          login_id: user.login_id
        }
      }, status: :ok

    when :invalid
      render json: {
        error: payload
      }, status: :bad_request

    when :unauthorized
      render json: {
        error: payload
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