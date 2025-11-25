Rails.application.routes.draw do
  # 認証
  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  delete "/logout", to: "auth#logout"

  # ワークスペース
  resources :workspaces, only: %i[index create show update destroy]  do
    # タスク
    resources :tasks, only: %i[index show create update destroy]
    resources :task_progresses, only: %i[index]
    resources :members, only: %i[create update destroy]
  end
end