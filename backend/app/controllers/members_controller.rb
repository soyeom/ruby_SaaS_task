class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace
  before_action :authorize_owner!

  # POST /workspaces/:workspace_id/members
  def create
    role = params[:role] || "member"

    status, payload = WorkspaceMembersService.add_member(
      workspace: @workspace,
      login_id: params[:login_id],
      role: role
    )

    case status
    when :ok
      member = payload
      user   = member.user

      render json: {
        message: "メンバーを追加しました。",
        member: {
          id:   member.id,
          role: member.role,
          user: {
            id:       user.id,
            login_id: user.login_id
          }
        }
      }, status: :created

    when :invalid
      render json: { error: payload }, status: :bad_request

    when :user_not_found
      render json: { error: payload }, status: :not_found

    when :already_member
      render json: { error: payload }, status: :unprocessable_entity

    when :validation_failed
      render json: {
        error:   "メンバーの追加に失敗しました。",
        details: payload
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