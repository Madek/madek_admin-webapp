class ContextsController < ApplicationController
  def index
    @contexts = Context.all
  end

  def show
    @context = Context.find(params[:id])
  end

  def edit
    @context = Context.find(params[:id])
  end

  def update
    @context = Context.find(params[:id])
    @context.update context_params

    respond_with @context
  end

  private

  def context_params
    params.require(:context).permit(:label,
                                    :description,
                                    :admin_comment)
  end
end
