class TaskProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace
  before_action :authorize_member!

  # GET /workspaces/:workspace_id/task_progresses
  def index
    progresses = @workspace.task_progresses.includes(:user)

    render json: progresses.map { |p|
      {
        user: {
          id:       p.user.id,
          login_id: p.user.login_id
        },
        total_tasks:     p.total_tasks,
        completed_tasks: p.completed_tasks,
        completion_rate: p.completion_rate,
        aggregated_at:   p.aggregated_at
      }
    }
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def authorize_member!
    unless @workspace.members.exists?(user_id: current_user.id)
      render json: { error: "アクセス権限がありません。" }, status: :forbidden
    end
  end
end
