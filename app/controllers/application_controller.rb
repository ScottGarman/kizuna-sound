class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :site_settings

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # The singleton global site settings, available to every view.
  def site_settings
    @site_settings ||= Setting.current
  end

  def logged_in?
    current_user.present?
  end

  def require_admin
    return if logged_in?

    redirect_to login_path, alert: "Please log in to continue."
  end
end
