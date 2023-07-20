class MetaKeyPolicy < DefaultPolicy
  def edit?
    true
  end

  def update?
    edit?
  end

  def destroy?
    not @record.core?
  end

  def move_to_top?
    not @record.core?
  end

  def move_up?
    not @record.core?
  end

  def move_down?
    not @record.core?
  end

  def move_to_bottom?
    not @record.core?
  end
end
