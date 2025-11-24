class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace
  before_action :authorize_member!
  before_action :set_task, only: %i[show update destroy]

  # GET /workspaces/:workspace_id/tasks
  def index
    tasks = @workspace.tasks

    # ステータスフィルタ
    if params[:status].present?
      status_list = params[:status].split(",")
      valid_statuses = status_list & Task.statuses.keys

      if valid_statuses.any?
        tasks = tasks.where(status: valid_statuses)
      else
        return render json: { error: "不正なステータスが指定されました。" },
                      status: :bad_request
      end
    end

    # カテゴリフィルタ
    if params[:category].present?
      tasks = tasks.where(category: params[:category])
    end

    # 担当者フィルタ
    if params[:assignee_id].present?
      tasks = tasks.where(assignee_id: params[:assignee_id])
    end

    render json: tasks.as_json(
      only: [:id, :title, :status, :category, :assignee_id]
    )
  end


  # GET /workspaces/:workspace_id/tasks/:id
  def show
    render json: {
      id:           @task.id,
      title:        @task.title,
      description:  @task.description,
      status:       @task.status,
      category:     @task.category,
      workspace_id: @task.workspace_id,
      assignee_id:  @task.assignee_id
    }
  end

  # POST /workspaces/:workspace_id/tasks
  def create
    title       = params[:title]
    description = params[:description]
    status      = params[:status]      # "todo" / "doing" / "done"
    category    = params[:category]
    assignee_id = params[:assignee_id]

    # 必須チェック
    if title.blank?
      return render json: { error: "タスクタイトルは必須です。" },
                    status: :bad_request
    end

    task = @workspace.tasks.new(
      title:       title,
      description: description,
      category:    category
    )

    # ステータス設定（任意）
    task.status = status if status.present?

    # 担当者設定（任意）
    task.assignee_id = assignee_id if assignee_id.present?

    unless task.save
      return render json: {
        error: "タスクの作成に失敗しました。",
        details: task.errors.full_messages
      }, status: :unprocessable_entity
    end

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
  end

  # PATCH/PUT /workspaces/:workspace_id/tasks/:id
  def update
    update_attrs = task_params

    if @task.update(update_attrs)
      render json: {
        message: "タスクを更新しました。",
        task: {
          id:           @task.id,
          title:        @task.title,
          description:  @task.description,
          status:       @task.status,
          category:     @task.category,
          workspace_id: @task.workspace_id,
          assignee_id:  @task.assignee_id
        }
      }, status: :ok
    else
      render json: {
        error: "タスクの更新に失敗しました。",
        details: @task.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /workspaces/:workspace_id/tasks/:id
  def destroy
    @task.destroy
    render json: { message: "タスクを削除しました。" }, status: :ok
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