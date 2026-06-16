class SoundsController < ApplicationController
  before_action :require_admin, only: %i[new create edit update destroy]
  before_action :load_all_tags, only: %i[new create edit update]
  before_action :set_sound, only: %i[show edit update destroy play]

  def index
    @sounds = Sound.with_attached_audio.includes(:tags).order(created_at: :desc)

    # All tag features are off when the admin disables tags: no filtering (even
    # via a stray ?tag= URL) and no tag list. @active_tag/@tags stay nil and the
    # views skip every tag surface accordingly.
    if site_settings.tags_enabled?
      if params[:tag].present?
        @active_tag = Tag.find_by(name: Tag.normalize(params[:tag]))
        @sounds = @active_tag ? @sounds.joins(:taggings).where(taggings: { tag_id: @active_tag.id }) : Sound.none
      end

      # Tags that are actually in use (inner join), with a count for the filter list.
      @tags = Tag.joins(:taggings).group("tags.id").order(:name).select("tags.*, COUNT(taggings.id) AS sounds_count")
    end
  end

  def show
    # If reached via an outdated slug (FriendlyId history), 301 to the canonical
    # URL so search engines and shares consolidate on the current slug.
    redirect_to sound_path(@sound), status: :moved_permanently if request.path != sound_path(@sound)
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
  end

  def update
    if @sound.update(sound_params)
      redirect_to root_path, notice: "“#{@sound.title}” was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sound.destroy
    redirect_to root_path, notice: "“#{@sound.title}” was deleted."
  end

  # Records a completed play. Called by the waveform player's "finish" event, so
  # only full playbacks count. increment_counter is a single atomic UPDATE, so
  # concurrent plays don't clobber each other, and it skips validations,
  # callbacks, and timestamp bumps.
  def play
    Sound.increment_counter(:play_count, @sound.id)
    head :no_content
  end

  private

  # Look up by slug (FriendlyId). #friendly also resolves historical slugs, so
  # links shared before a title edit still find the right sound.
  def set_sound
    @sound = Sound.friendly.find(params[:id])
  end

  def sound_params
    params.require(:sound).permit(:title, :description, :audio, :new_tag_names, tag_ids: [])
  end

  def load_all_tags
    @all_tags = Tag.order(:name)
  end
end
