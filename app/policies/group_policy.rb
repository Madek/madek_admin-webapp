class GroupPolicy < DefaultPolicy
  def update?
    true
  end

  def destroy?
    true
  end

  def form_add_user?
    true
  end

  def add_user?
    true
  end

  def form_merge_to?
    false
  end

  def merge_to?
    false
  end

  def remove_user_from_group?
    true
  end
end
