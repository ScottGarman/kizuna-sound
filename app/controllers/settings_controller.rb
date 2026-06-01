class SettingsController < ApplicationController
  before_action :require_admin
  before_action :set_setting

  def show
  end

  def update
    if @setting.update(setting_params)
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
      :title, :about,
      links_attributes: %i[id title url _destroy]
    )
  end
end
