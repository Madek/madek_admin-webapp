class AdminPolicy < DefaultPolicy
  def initialize(user, permission_key)
    @user = user
    @permission_key = permission_key
  end

  def has_permission?
    return false unless user

    permission_key == :any ? user.any_admin_permission? : user.has_admin_permission?(permission_key)
  end

  private

  attr_reader :permission_key
end
