class TaskProgress < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  validates :workspace_id, :total_tasks, :completed_tasks, :completion_rate, presence: true, uniqueness: { scope: :user_id }
end
