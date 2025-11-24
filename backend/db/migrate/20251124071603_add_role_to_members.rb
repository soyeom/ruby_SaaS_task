class AddRoleToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :role, :integer, null: false, default: 0
  end
end
