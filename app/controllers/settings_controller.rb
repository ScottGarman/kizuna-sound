class SettingsController < ApplicationController
  before_action :require_admin
  before_action :set_setting

  def show
  end

  def update
    # Whether the form included a new banner upload. Used so that checking
    # "Remove banner" while also uploading a replacement keeps the new one.
    uploading_banner = params.dig(:setting, :banner).present?

    if @setting.update(setting_params)
      @setting.banner.purge if @setting.remove_banner == "1" && !uploading_banner
      redirect_to settings_path, notice: "Settings saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_setting
    @setting = Setting.current
  end

  def setting_params
    params.require(:setting).permit(
      :title, :about, :tags_enabled, :banner, :remove_banner, :banner_overlay,
      links_attributes: %i[id title url _destroy]
    )
  end
end
