class AuthenticationGroupPolicy < GroupPolicy
  def destroy?
    false
  end

  def form_add_user?
    false
  end

  def add_user?
    false
  end

  def remove_user_from_group?
    false
  end
end
