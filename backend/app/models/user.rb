class User < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :workspaces, through: :members

  has_many :assigned_tasks,
           class_name: "Task",
           foreign_key: :assignee_id,
           dependent: :nullify

  has_many :task_progresses, dependent: :destroy

  validates :login_id, presence: true, uniqueness: true
  validates :password, presence: true
end
