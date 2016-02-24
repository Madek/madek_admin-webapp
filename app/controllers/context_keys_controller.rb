class ContextKeysController < ApplicationController

  def edit
    @context_key = ContextKey.find(params[:id])
  end

  def update
    @context_key = ContextKey.find(params[:id])
    @context_key.update!(context_key_params)

    respond_with @context_key, location: (lambda do
      context_path(@context_key.context)
    end)
  end

  %i(up down).each do |direction|
    define_method "move_#{direction}" do
      context_key = ContextKey.find(params[:id])
      context_key.send("move_#{direction}")

      redirect_to context_path(context_key.context), flash: {
        success: "The Context Key was successfully moved #{direction}."
      }
    end
  end

  private

  def context_key_params
    params.require(:context_key).permit(:label,
                                        :description,
                                        :hint,
                                        :is_required,
                                        :length_min,
                                        :length_max,
                                        :input_type,
                                        :admin_comment)
  end
end
