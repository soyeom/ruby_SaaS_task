class ApplicationController < ActionController::API
  include ActionController::Cookies

  private

  # 現在のログインユーザーを取得
  def current_user
    # セッションにユーザーIDがない場合
    return nil unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
  end

  # ログインチェック
  def authenticate_user!
    unless current_user
      render json: { error: "ログインが必要です。" }, status: :unauthorized
    end
  end
end
