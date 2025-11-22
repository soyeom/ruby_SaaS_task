class CreateTaskProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :task_progresses do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :total_tasks, null: false, default: 0
      t.integer :completed_tasks, null: false, default: 0
      t.integer :completion_rate, null: false, default: 0  # 0~100
      t.datetime :aggregated_at, null: false

      t.timestamps
    end
    add_index :task_progresses, [:workspace_id, :user_id], unique: true
  end
end
