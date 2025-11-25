class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace
  before_action :authorize_member!
  before_action :set_task, only: %i[show update destroy]

  # GET /workspaces/:workspace_id/tasks
  def index
    status, payload = TaskService.list(
      workspace:    @workspace,
      status_param: params[:status],
      category:     params[:category],
      assignee_id:  params[:assignee_id]
    )

    case status
    when :ok
      tasks = payload
      render json: tasks.as_json(
        only: [:id, :title, :status, :category, :assignee_id]
      )

    when :invalid_status
      render json: { error: payload }, status: :bad_request
    end
  end

  # GET /workspaces/:workspace_id/tasks/:id
  def show
    status, payload = TaskService.show(task: @task)

    case status
    when :ok
      render json: payload, status: :ok
    end
  end

  # POST /workspaces/:workspace_id/tasks
  def create
    status, payload = TaskService.create(
      workspace:   @workspace,
      title:       params[:title],
      description: params[:description],
      status:      params[:status],
      category:    params[:category],
      assignee_id: params[:assignee_id]
    )

    case status
    when :ok
      task = payload
      render json: {
        message: "タスクを作成しました。",
        task: {
          id:           task.id,
          title:        task.title,
          description:  task.description,
          status:       task.status,
          category:     task.category,
          workspace_id: task.workspace_id,
          assignee_id:  task.assignee_id
        }
      }, status: :created

    when :invalid
      render json: {
        error: payload
      }, status: :bad_request

    when :validation_failed
      render json: {
        error:   "タスクの作成に失敗しました。",
        details: payload
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /workspaces/:workspace_id/tasks/:id
  def update
    status, payload = TaskService.update(
      task:  @task,
      attrs: task_params
    )

    case status
    when :ok
      task = payload
      render json: {
        message: "タスクを更新しました。",
        task: {
          id:           task.id,
          title:        task.title,
          description:  task.description,
          status:       task.status,
          category:     task.category,
          workspace_id: task.workspace_id,
          assignee_id:  task.assignee_id
        }
      }, status: :ok

    when :validation_failed
      render json: {
        error:   "タスクの更新に失敗しました。",
        details: payload
      }, status: :unprocessable_entity
    end
  end

  # DELETE /workspaces/:workspace_id/tasks/:id
  def destroy
    status, _ = TaskService.destroy(task: @task)

    case status
    when :ok
      render json: { message: "タスクを削除しました。" }, status: :ok
    end
  end

  private

  def task_params
    params.permit(:title, :description, :status, :category, :assignee_id)
  end

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_task
    @task = @workspace.tasks.find(params[:id])
  end

  def authorize_member!
    unless @workspace.members.exists?(user_id: current_user.id)
      render json: { error: "アクセス権限がありません。" }, status: :forbidden
    end
  end
end