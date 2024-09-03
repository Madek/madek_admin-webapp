module ActionMethods
  extend ActiveSupport::Concern

  module ClassMethods
    def define_update_action_for(model, perform_authorization = false)
      model_underscored = model.to_s.underscore
      define_method :update do
        @instance = model.find(params[:id])
        authorize(@instance) if perform_authorization
        @instance.update!(send("update_#{model_underscored}_params"))

        respond_with @instance, location: (lambda do
          send("#{model_underscored}_path", @instance)
        end)
      end
    end

    def define_destroy_action_for(model, perform_authorization = false)
      define_method :destroy do
        @instance = model.find(params[:id])
        authorize(@instance) if perform_authorization
        @instance.destroy!

        respond_with @instance, location: (lambda do
          send("#{model.model_name.plural}_path")
        end)
      end
    end

    def define_move_actions_for(model, perform_authorization = false, &block)
      %i(to_top up down to_bottom).each do |direction|
        define_method "move_#{direction}" do
          resource = model.find(params[:id])
          authorize(resource) if perform_authorization
          resource.send "move_#{direction}"
          success_path = instance_exec(resource, &block)
          direction_name = direction.to_s.split('_').join(' ')

          redirect_to success_path, flash: {
            success: "The #{model.model_name.name} was successfully moved
                      #{direction_name}."
          }
        end
      end
    end
  end
end
