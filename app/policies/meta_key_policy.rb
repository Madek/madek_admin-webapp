class MetaKeyPolicy < DefaultPolicy
  def edit?
    @record.vocabulary_id != 'madek_core'
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def move_to_top?
    edit?
  end

  def move_up?
    edit?
  end

  def move_down?
    edit?
  end

  def move_to_bottom?
    edit?
  end
end
