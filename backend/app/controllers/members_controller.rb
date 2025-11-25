class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace
  before_action :authorize_owner!

  # POST /workspaces/:workspace_id/members
  def create
    login_id = params[:login_id]
    role     = params[:role] || "member"

    if login_id.blank?
      return render json: { error: "login_id は必須です。" }, status: :bad_request
    end

    user = User.find_by(login_id: login_id)
    if user.nil?
      return render json: { error: "指定された login_id のユーザーが見つかりません。" },
                    status: :not_found
    end

    if @workspace.members.exists?(user_id: user.id)
      return render json: { error: "このユーザーは既にワークスペースのメンバーです。" },
                    status: :unprocessable_entity
    end

    member = @workspace.members.new(user: user, role: role)

    if member.save
      render json: {
        message: "メンバーを追加しました。",
        member: {
          id: member.id,
          role: member.role,
          user: {
            id:       user.id,
            login_id: user.login_id
          }
        }
      }, status: :created
    else
      render json: {
        error:   "メンバーの追加に失敗しました。",
        details: member.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def authorize_owner!
    unless @workspace.members.exists?(user_id: current_user.id, role: :owner)
      render json: { error: "オーナーのみメンバーを追加できます。" }, status: :forbidden
    end
  end
end
