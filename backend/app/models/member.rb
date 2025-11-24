# app/models/member.rb
class Member < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  enum :role, { owner: 0, member: 1 }

  validates :user_id, uniqueness: { scope: :workspace_id }
end
