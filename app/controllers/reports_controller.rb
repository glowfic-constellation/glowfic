class ReportsController < ApplicationController
  around_filter :set_fixed_timezone

  def index
  end

  def show
    unless ['daily', 'monthly'].include?(params[:id])
      flash[:error] = "Could not identify the type of report."
      redirect_to reports_path
    end
  end

  private

  def set_fixed_timezone(&block)
    Time.use_zone("Alaska", &block)
  end
end
