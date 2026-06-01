class SettingsController < ApplicationController
  before_action :require_admin
  before_action :set_setting

  def show
  end

  private

  def set_setting
    @setting = Setting.current
  end
end
