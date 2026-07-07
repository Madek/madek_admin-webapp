module ContextPermissions
  extend ActiveSupport::Concern

  included do
    before_action :find_and_set_context
  end

  module ClassMethods
    def define_actions_for(association)
      define_create_action_for association
      define_edit_action_for association
      define_update_action_for association
    end

    def define_create_action_for(association)
      define_method :create do
        @context
          .send(association)
          .create!(permission_params.merge(creator_id: current_user.id))
        session[:context_permission_context_id] = nil

        redirect_to send(redirect_path(association), @context),
                    flash: {
                      success: 'The Context ' \
                                "#{success_message(association)} " \
                                'Permission has been created.' }
      end
    end

    def define_edit_action_for(association)
      define_method :edit do
        @permission = @context.send(association).find(params[:id])
        association_foreign_key = parent_id(association)
        if params[association_foreign_key]
          @permission.send("#{association_foreign_key}=",
                            params[association_foreign_key])
        end
      end
    end

    def define_update_action_for(association)
      define_method :update do
        permission = @context.send(association).find(params[:id])
        permission.update!(permission_params.merge(updator_id: current_user.id))
        session[:context_permission_context_id] = nil

        redirect_to send(redirect_path(association), @context),
                    flash: {
                      success: 'The Context ' \
                                "#{success_message(association)} " \
                                'Permission has been updated.' }
      end
    end
  end

  private

  def find_and_set_context
    @context = Context.find(params[:context_id])
  end

  def parent_id(association)
    "#{association_without_suffix(association)}_id".to_sym
  end

  def association_without_suffix(association)
    association.to_s.split('_')[0..-2].join('_')
  end

  def redirect_path(association)
    "context_context_#{association}_path"
  end

  def success_message(association)
    success_message = association.to_s.split('_')
    success_message.take(success_message.length - 1).join(' ').titleize
  end
end
