namespace :task_progress do
  desc "ワークスペース × 担当者ごとのタスク進捗を集計するバッチ"
  task aggregate: :environment do
    puts "タスク進捗集計を開始します..."

    Workspace.find_each do |workspace|
      puts "  workspace: #{workspace.id} (#{workspace.name})"

      # 担当者が設定されているタスクのみ対象
      tasks = workspace.tasks.where.not(assignee_id: nil)

      # userごとの総タスク数
      total_by_user = tasks.group(:assignee_id).count
      # userごとの完了タスク数（status = done）
      done_by_user  = tasks.where(status: :done).group(:assignee_id).count

      # 集計対象ユーザーID一覧
      user_ids = total_by_user.keys

      user_ids.each do |user_id|
        total     = total_by_user[user_id] || 0
        completed = done_by_user[user_id]  || 0

        rate = if total.zero?
                 0
               else
                 ((completed.to_f / total.to_f) * 100).round
               end

        progress = TaskProgress.find_or_initialize_by(
          workspace_id: workspace.id,
          user_id:      user_id
        )

        progress.total_tasks     = total
        progress.completed_tasks = completed
        progress.completion_rate = rate
        progress.aggregated_at   = Time.current

        if progress.changed?
          progress.save!
          puts "    updated user_id=#{user_id}: total=#{total}, done=#{completed}, rate=#{rate}%"
        else
          puts "    no change user_id=#{user_id}"
        end
      end
    end

    puts "タスク進捗集計が完了しました。"
  end
end