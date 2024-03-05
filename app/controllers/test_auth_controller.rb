if Rails.env.development? or Rails.env.test?

  class TestAuthController < ApplicationController
    include Concerns::MadekCookieSession
    include Concerns::RedirectBackOr

    skip_before_action :authorize_admin

    def show
    end

    def sign_in
      @user = User.find_by(login: params[:login].try(&:downcase))

      if @user and @user.authenticate(params[:password])
        set_madek_session(@user, AuthSystem.find_by!(id: 'password'), true)
        redirect_to(root_path)
      else
        destroy_madek_session
        redirect_to(root_path)
      end
    end

    def sign_out
      destroy_madek_session
      reset_session
      redirect_to(test_login_path)
    end
  end

end
