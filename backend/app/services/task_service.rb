class TaskService
  # タスク一覧取得 + フィルタリング
  def self.list(workspace:, status_param:, category:, assignee_id:)
    tasks = workspace.tasks

    # ステータスフィルタ
    if status_param.present?
      status_list    = status_param.split(",")
      valid_statuses = status_list & Task.statuses.keys

      if valid_statuses.any?
        tasks = tasks.where(status: valid_statuses)
      else
        return [:invalid_status, "不正なステータスが指定されました。"]
      end
    end

    # カテゴリフィルタ
    tasks = tasks.where(category: category) if category.present?

    # 担当者フィルタ
    tasks = tasks.where(assignee_id: assignee_id) if assignee_id.present?

    [:ok, tasks]
  end

  # タスク詳細
  def self.show(task:)
    data = {
      id:           task.id,
      title:        task.title,
      description:  task.description,
      status:       task.status,
      category:     task.category,
      workspace_id: task.workspace_id,
      assignee_id:  task.assignee_id
    }

    [:ok, data]
  end

  # タスク作成
  def self.create(workspace:, title:, description:, status:, category:, assignee_id:)
    return [:invalid, "タスクタイトルは必須です。"] if title.blank?

    task = workspace.tasks.new(
      title:       title,
      description: description,
      category:    category
    )

    task.status      = status      if status.present?
    task.assignee_id = assignee_id if assignee_id.present?

    if task.save
      [:ok, task]
    else
      [:validation_failed, task.errors.full_messages]
    end
  end

  # タスク更新
  def self.update(task:, attrs:)
    if task.update(attrs)
      [:ok, task]
    else
      [:validation_failed, task.errors.full_messages]
    end
  end

  # タスク削除
  def self.destroy(task:)
    task.destroy
    [:ok, nil]
  end
end