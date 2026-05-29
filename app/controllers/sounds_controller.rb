class SoundsController < ApplicationController
  before_action :require_admin, only: %i[new create destroy]

  def index
    @sounds = Sound.with_attached_audio.order(created_at: :desc)
  end

  def new
    @sound = Sound.new
  end

  def create
    @sound = current_user.sounds.build(sound_params)

    if @sound.save
      redirect_to root_path, notice: "“#{@sound.title}” was uploaded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @sound = Sound.find(params[:id])
    @sound.destroy
    redirect_to root_path, notice: "“#{@sound.title}” was deleted."
  end

  private

  def sound_params
    params.require(:sound).permit(:title, :audio)
  end
end
