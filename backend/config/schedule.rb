set :output, "log/cron.log"

# 1時間ごとにタスク進捗を集計
every 1.hour do
  rake "task_progress:aggregate"
end