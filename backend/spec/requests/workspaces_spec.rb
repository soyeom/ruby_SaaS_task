require "rails_helper"

RSpec.describe "Workspaces API", type: :request do
  describe "GET /workspaces" do
    context "ログインしていない場合" do
      it "401 Unauthorized を返すこと" do
        get "/workspaces"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "ログインしている場合" do
      let(:password) { "password123" }
      let!(:user) do
        User.create!(
          login_id: "test_user",
          password: password,
          password_confirmation: password
        )
      end

      let!(:workspace) do
        ws = Workspace.create!(name: "テスト用ワークスペース")
        # オーナーとしてメンバー登録
        ws.members.create!(user: user, role: :owner)
        ws
      end

      it "200 OK と、自分が所属するワークスペース一覧を返すこと" do
        # まずログイン
        post "/login", params: {
          login_id: user.login_id,
          password: password
        }

        expect(response).to have_http_status(:ok)

        # 同じセッションで /workspaces にアクセス
        get "/workspaces"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to be >= 1
        # index: workspaces.as_json(only: [:id, :name])
        expect(json.first["name"]).to eq("テスト用ワークスペース")
      end
    end
  end
end
