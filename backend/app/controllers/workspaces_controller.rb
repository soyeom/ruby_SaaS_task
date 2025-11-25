class WorkspacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace, only: %i[show update destroy]
  before_action :authorize_member!, only: %i[show update destroy]

  # GET /workspaces
  def index
    workspaces = current_user.workspaces

    render json: workspaces.as_json(only: [:id, :name])
  end

  # GET /workspaces/:id
  def show
    status, payload = WorkspaceService.show(workspace: @workspace)

    case status
    when :ok
      render json: payload, status: :ok
    end
  end

  # POST /workspaces
  def create
    status, payload = WorkspaceService.create(
      name:  params[:name],
      owner: current_user
    )

    case status
    when :ok
      workspace = payload
      render json: {
        message: "ワークスペースを作成しました。",
        workspace: {
          id:   workspace.id,
          name: workspace.name
        }
      }, status: :created

    when :invalid
      render json: {
        error: payload
      }, status: :bad_request

    when :validation_failed
      render json: {
        error:   "ワークスペースの作成に失敗しました。",
        details: payload
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /workspaces/:id
  def update
    status, payload = WorkspaceService.update(
      workspace: @workspace,
      params: workspace_params
    )

    case status
    when :ok
      workspace = payload
      render json: {
        message: "ワークスペースを更新しました。",
        workspace: {
          id:   workspace.id,
          name: workspace.name
        }
      }, status: :ok

    when :validation_failed
      render json: {
        error:   "ワークスペースの更新に失敗しました。",
        details: payload
      }, status: :unprocessable_entity
    end
  end

  # DELETE /workspaces/:id
  def destroy
    status, _ = WorkspaceService.destroy(workspace: @workspace)

    case status
    when :ok
      render json: { message: "ワークスペースを削除しました。" }, status: :ok
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def authorize_member!
    unless @workspace.users.exists?(id: current_user.id)
      render json: { error: "アクセス権限がありません。" }, status: :forbidden
    end
  end

  def workspace_params
    params.require(:workspace).permit(:name)
  end
end