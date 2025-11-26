namespace :task_progress do
  desc "ワークスペース × 担当者ごとのタスク進捗を集計するバッチ"
  task aggregate: :environment do
    puts "タスク進捗集計を開始します..."

    Workspace.find_each do |workspace|
      puts "  workspace: #{workspace.id} (#{workspace.name})"

      tasks = workspace.tasks.where.not(assignee_id: nil)

      total_by_user = tasks.group(:assignee_id).count
      done_by_user  = tasks.where(status: :done).group(:assignee_id).count

      user_ids = total_by_user.keys

      user_ids.each do |user_id|
        total     = total_by_user[user_id] || 0
        completed = done_by_user[user_id]  || 0

        rate =
          if total.zero?
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

  # ✅ 여기부터 새로운 정기 집계용 태스크
  desc "タスク進捗集計バッチを定期的に実行するデーモン"
  task daemon: :environment do
    require "rufus-scheduler"

    scheduler = Rufus::Scheduler.new

    # 🔁 주기 설정: 예) 5분마다
    scheduler.every "5m" do
      puts "[#{Time.current}] task_progress:aggregate を実行します"

      # Rake 태스크는 한 번 invoke 되면 다시 못 쓰니까 reenable 필요
      Rake::Task["task_progress:aggregate"].reenable
      Rake::Task["task_progress:aggregate"].invoke
    end

    puts "task_progress:daemon 起動中... (Ctrl+C で停止)"

    # スケジューラが 動作し続けるようにする
    scheduler.join
  end
end