class SoundsController < ApplicationController
  before_action :require_admin, only: %i[new create edit update destroy]
  before_action :load_all_tags, only: %i[new create edit update]

  def index
    @sounds = Sound.with_attached_audio.includes(:tags).order(created_at: :desc)

    if params[:tag].present?
      @active_tag = Tag.find_by(name: Tag.normalize(params[:tag]))
      @sounds = @active_tag ? @sounds.joins(:taggings).where(taggings: { tag_id: @active_tag.id }) : Sound.none
    end

    # Tags that are actually in use (inner join), with a count for the filter list.
    @tags = Tag.joins(:taggings).group("tags.id").order(:name).select("tags.*, COUNT(taggings.id) AS sounds_count")
  end

  def show
    @sound = Sound.find(params[:id])
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

  def edit
    @sound = Sound.find(params[:id])
  end

  def update
    @sound = Sound.find(params[:id])

    if @sound.update(sound_params)
      redirect_to root_path, notice: "“#{@sound.title}” was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sound = Sound.find(params[:id])
    @sound.destroy
    redirect_to root_path, notice: "“#{@sound.title}” was deleted."
  end

  private

  def sound_params
    params.require(:sound).permit(:title, :audio, :new_tag_names, tag_ids: [])
  end

  def load_all_tags
    @all_tags = Tag.order(:name)
  end
end
