Rails.application.routes.draw do
  # 認証
  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  delete "/logout", to: "auth#logout"

  # ワークスペース
  resources :workspaces, only: %i[index create show update destroy]
end