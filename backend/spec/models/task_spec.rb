# spec/models/task_spec.rb
require "rails_helper"

RSpec.describe Task, type: :model do
  let(:workspace) { Workspace.create!(name: "テスト用ワークスペース") }

  describe "バリデーション" do
    it "タイトルとワークスペースがあれば有効であること" do
      task = Task.new(
        title: "ログイン画面のバグ修正",
        workspace: workspace,
        status: :todo
      )

      expect(task).to be_valid
    end

    it "タイトルが空だと無効であること" do
      task = Task.new(
        title: "",
        workspace: workspace,
        status: :todo
      )

      expect(task).not_to be_valid
      expect(task.errors[:title]).to include("を入力してください").or include("can't be blank")
    end
  end
end
