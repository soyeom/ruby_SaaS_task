class WorkspaceService
  def self.create(name:, owner:)
    return [:invalid, "ワークスペース名は必須です。"] if name.blank?

    workspace = nil

    begin
      Workspace.transaction do
        workspace = Workspace.create!(name: name)
        workspace.members.create!(user: owner, role: :owner)
      end

      [:ok, workspace]
    rescue ActiveRecord::RecordInvalid => e
      [:validation_failed, e.record.errors.full_messages]
    end
  end

  # ワークスペース更新
  def self.update(workspace:, params:)
    if workspace.update(params)
      [:ok, workspace]
    else
      [:validation_failed, workspace.errors.full_messages]
    end
  end

  # ワークスペース削除
  def self.destroy(workspace:)
    workspace.destroy
    [:ok, nil]
  end

  # ワークスペース詳細取得
  def self.show(workspace:)
    data = {
      id: workspace.id,
      name: workspace.name,
      members: workspace.members.includes(:user).map { |m|
        {
          id: m.id,
          role: m.role,
          user: {
            id:       m.user.id,
            login_id: m.user.login_id
          }
        }
      },
      tasks: workspace.tasks.map { |t|
        {
          id: t.id,
          title: t.title,
          status: t.status,
          assignee_id: t.assignee_id
        }
      }
    }

    [:ok, data]
  end
end