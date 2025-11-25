class WorkspacesController < ApplicationController
  # 認証済みユーザーのみアクセス可能にする
  before_action :authenticate_user!
  before_action :set_workspace, only: %i[show update destroy]
  before_action :authorize_member!, only: %i[show update destroy]

  # GET /workspaces
  # ワークスペース一覧取得
  def index
    workspaces = current_user.workspaces

    render json: workspaces.as_json(only: [:id, :name])
  end

  # GET /workspaces/:id
  def show
  render json: {
    id: @workspace.id,
    name: @workspace.name,
    members: @workspace.members.includes(:user).map { |m|
      {
        id: m.id,
        role: m.role,
        user: {
          id: m.user.id,
          login_id: m.user.login_id
        }
      }
    },
    tasks: @workspace.tasks.map { |t|
      {
        id: t.id,
        title: t.title,
        status: t.status,
        assignee_id: t.assignee_id
      }
    }
  }
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

    begin
      Workspace.transaction do
        @workspace = Workspace.create!(name: name)
        @workspace.members.create!(user: current_user, role: :owner)
      end

      render json: {
        message: "ワークスペースを作成しました。",
        workspace: {
          id: @workspace.id,
          name: @workspace.name
        }
      }, status: :created

      rescue ActiveRecord::RecordInvalid => e
      render json: {
        error: "ワークスペースの作成に失敗しました。",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /workspaces/:id
  def update
    if @workspace.update(workspace_params)
      render json: {
        message: "ワークスペースを更新しました。",
        workspace: {
          id: @workspace.id,
          name: @workspace.name
        }
      }, status: :ok
    else
      render json: {
        error: "ワークスペースの更新に失敗しました。",
        details: @workspace.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

   # DELETE /workspaces/:id
  def destroy
    @workspace.destroy
    render json: { message: "ワークスペースを削除しました。" }, status: :ok
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def authorize_member!
    unless @workspace.users.exists?(id: current_user.id)
      return render json: { error: "アクセス権限がありません。" }, status: :forbidden
    end
  end

  def workspace_params
    params.require(:workspace).permit(:name)
  end
end
