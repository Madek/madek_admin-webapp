class TestAuthController < ApplicationController
  if Rails.env.development? or Rails.env.test?

    include MadekCookieSession
    include RedirectBackOr

    skip_before_action :authorize_admin

    def show
    end

    def sign_in
      login_or_email = params[:login].try(&:downcase)
      @user = User.find_by(login: login_or_email) || User.where("LOWER(email) = ?", login_or_email).first

      if @user and @user.authenticate(params[:password])
        set_madek_session(@user, AuthSystem.find_by!(id: "password"), true)
        redirect_to(root_path)
      else
        destroy_madek_session
        flash[:error] = "Authentication failed."
        redirect_to("/admin/sign-in")
      end
    end

    def sign_out
      destroy_madek_session
      reset_session
      redirect_to(test_login_path)
    end

  end
end
