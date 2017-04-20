module Concerns
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

      def define_destroy_action_for(model)
        define_method :destroy do
          @instance = model.find(params[:id])
          @instance.destroy!

          respond_with @instance, location: (lambda do
            send("#{model.model_name.plural}_path")
          end)
        end
      end

      def define_move_actions_for(model, &block)
        %i(up down).each do |direction|
          define_method "move_#{direction}" do
            resource = model.find(params[:id])
            resource.send "move_#{direction}"
            success_path = instance_exec(resource, &block)
            model_name = model.to_s.humanize.capitalize

            redirect_to success_path, flash: {
              success: "The #{model_name} was successfully moved #{direction}."
            }
          end
        end
      end
    end
  end
end
