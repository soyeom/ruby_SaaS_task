class Member < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  validates :user_id, uniqueness: { scope: :workspace_id }
end
