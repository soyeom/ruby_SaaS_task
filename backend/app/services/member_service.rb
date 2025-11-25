class MemberService
  def self.add_member(workspace:, login_id:, role: "member")
    return [:invalid, "login_id は必須です。"] if login_id.blank?

    user = User.find_by(login_id: login_id)
    return [:user_not_found, "指定された login_id のユーザーが見つかりません。"] unless user

    if workspace.members.exists?(user_id: user.id)
      return [:already_member, "このユーザーは既にワークスペースのメンバーです。"]
    end

    member = workspace.members.new(user: user, role: role)

    if member.save
      [:ok, member]
    else
      [:validation_failed, member.errors.full_messages]
    end
  end
end