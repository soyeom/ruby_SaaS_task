class AuthController < ApplicationController
  # POST /signup
  def signup
    login_id      = params[:login_id]
    password      = params[:password]
    password_conf = params[:password_conf]

    # 必須チェック
    if login_id.blank? || password.blank? || password_conf.blank?
      return render json: { error: "login_id, password, password_conf は必須です。" },
                    status: :bad_request
    end

    user = User.new( 
      login_id: login_id, 
      password: password,
      password_confirmation: password_conf 
    )

    if user.save
      render json: { 
        message: "ユーザー登録が完了しました。", 
        user: {
            id: user.id,
            login_id: user.login_id
          }
        }, status: :created
    else
      render json: { 
        error: "ユーザー登録に失敗しました。", 
        details: user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
end