module ResponsibleEntityPath
  extend ActiveSupport::Concern

  included do
    helper_method :responsible_entity_path
  end

  def responsible_entity_path(media_resource)
    if media_resource.responsible_user
      user_path(media_resource.responsible_user)
    elsif media_resource.responsible_delegation
      delegation_path(media_resource.responsible_delegation)
    else
      raise('No responsible entity!')
    end
  end
end
