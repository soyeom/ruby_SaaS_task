class Workspace < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :users, through: :members

  has_many :tasks, dependent: :destroy
  has_many :task_progresses, dependent: :destroy

  validates :name, presence: true
end
