class WorkspacesController < ApplicationController
  # 認証済みユーザーのみアクセス可能にする
  before_action :authenticate_user!

  # GET /workspaces
  # ワークスペース一覧取得
  def index
    workspaces = current_user.workspaces

    render json: workspaces.as_json(only: [:id, :name])
  end

  # POST /workspaces
  # ワークスペース作成
  def create
    name = params[:name]

    # 必須チェック
    if name.blank?
      return render json: { error: "ワークスペース名は必須です。" },
                    status: :bad_request
    end
    
    # current_user に紐づいたワークスペースを作成
    workspace = current_user.workspaces.build(name: name)

    if workspace.save
      render json: {
        message: "ワークスペースを作成しました。",
        workspace: {
          id: workspace.id,
          name: workspace.name
        }
      }, status: :created
    else
      render json: { 
        error: "ワークスペースの作成に失敗しました。", 
        details: workspace.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  private

  def workspace_params
    params.permit(:name, :description)
  end
end
