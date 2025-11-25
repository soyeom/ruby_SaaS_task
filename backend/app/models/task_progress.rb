class TaskProgress < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  validates :total_tasks, :completed_tasks, :completion_rate, :aggregated_at, presence: true
  validates :completion_rate, inclusion: { in: 0..100 }

  validates :user_id, uniqueness: { scope: :workspace_id }
end