# frozen_string_literal: true
class SubcontinuitiesController < ApplicationController
  before_action :login_required, except: :show
  before_action :find_section, except: [:new, :create]
  before_action :require_permission, except: [:show, :update]

  def new
    @subcontinuity = Subcontinuity.new(continuity_id: params[:continuity_id])
    @page_title = 'New Section'
  end

  def create
    @subcontinuity = Subcontinuity.new(section_params)
    unless @subcontinuity.continuity.nil? || @subcontinuity.continuity.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to continuities_path and return
    end

    begin
      @subcontinuity.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Section could not be created.",
        array: @subcontinuity.errors.full_messages
      }
      @page_title = 'New Section'
      render :new
    else
      flash[:success] = "New section, #{@subcontinuity.name}, has successfully been created for #{@subcontinuity.continuity.name}."
      redirect_to edit_continuity_path(@subcontinuity.continuity)
    end
  end

  def show
    @page_title = @subcontinuity.name
    @posts = posts_from_relation(@subcontinuity.posts.ordered_in_section)
    @meta_og = og_data
  end

  def edit
    @page_title = 'Edit ' + @subcontinuity.name
    use_javascript('subcontinuities')
    gon.section_id = @subcontinuity.id
  end

  def update
    @subcontinuity.assign_attributes(section_params)
    require_permission
    return if performed?

    begin
      @subcontinuity.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Section could not be updated.",
        array: @subcontinuity.errors.full_messages
      }
      @page_title = 'Edit ' + @subcontinuity.name_was
      use_javascript('subcontinuities')
      gon.section_id = @subcontinuity.id
      render :edit
    else
      flash[:success] = "#{@subcontinuity.name} has been successfully updated."
      redirect_to subcontinuity_path(@subcontinuity)
    end
  end

  def destroy
    begin
      @subcontinuity.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Section could not be deleted.",
        array: @subcontinuity.errors.full_messages
      }
      redirect_to subcontinuity_path(@subcontinuity)
    else
      flash[:success] = "Section deleted."
      redirect_to edit_continuity_path(@subcontinuity.continuity)
    end
  end

  private

  def find_section
    @subcontinuity = Subcontinuity.find_by_id(params[:id])
    unless @subcontinuity
      flash[:error] = "Section not found."
      redirect_to continuities_path and return
    end
  end

  def require_permission
    continuity = @subcontinuity.try(:continuity) || Continuity.find_by_id(params[:continuity_id])
    if continuity && !continuity.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to continuities_path and return
    end
  end

  def og_data
    stats = []
    continuity = @subcontinuity.continuity
    stats << continuity.writers.where.not(deleted: true).ordered.pluck(:username).join(', ') if continuity.authors_locked?
    post_count = @subcontinuity.posts.where(privacy: Concealable::PUBLIC).count
    stats << "#{post_count} " + "post".pluralize(post_count)
    desc = [stats.join(' – ')]
    desc << generate_short(@subcontinuity.description) if @subcontinuity.description.present?
    {
      url: subcontinuity_url(@subcontinuity),
      title: "#{continuity.name} » #{@subcontinuity.name}",
      description: desc.join("\n"),
    }
  end

  def section_params
    params.fetch(:subcontinuity, {}).permit(
      :continuity_id,
      :name,
      :description,
    )
  end
end
