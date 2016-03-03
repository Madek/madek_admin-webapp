class ContextsController < ApplicationController
  def index
    @contexts = Context.all
  end

  def show
    @context = Context.find(params[:id])
  end

  def edit
    @context = Context.find(params[:id])

    if params[:forget_context_id].present?
      session[:context_id] = nil
    end
  end

  def update
    @context = Context.find(params[:id])
    @context.update! context_params

    respond_with @context
  end

  def new
    @context = Context.new
  end

  def create
    @context = Context.create!(new_context_params)

    respond_with @context, location: (lambda do
      contexts_path
    end)
  end

  def add_meta_key
    context = Context.find(params[:id])
    create_context_key_for(context)
    session[:context_id] = nil

    redirect_to edit_context_path(context), flash: {
      success: 'The Meta Key was successfully added to the Context.'
    }
  end

  private

  def context_params
    params.require(:context).permit(:label,
                                    :description,
                                    :admin_comment)
  end

  def new_context_params
    params.require(:context).permit(:id,
                                    :label,
                                    :description,
                                    :admin_comment)
  end

  def create_context_key_for(context)
    next_position = context.context_keys.last.position + 1 rescue 0
    ContextKey.create!(
      context: context,
      meta_key: MetaKey.find(params[:meta_key_id]),
      position: next_position
    )
  end
end
