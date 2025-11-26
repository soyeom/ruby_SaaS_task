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

  def self.remove_member(workspace:, member_id:)
    member = workspace.members.find_by(id: member_id)
    return [:not_found, "指定されたメンバーが見つかりません。"] unless member

    # （必要なら）最後のオーナー削除を禁止したい場合
    if member.role == "owner" && workspace.members.where(role: :owner).count == 1
      return [:cannot_remove_owner, "ワークスペースには少なくとも1人のオーナーが必要です。"]
    end

    member.destroy
    [:ok, nil]
  end
end