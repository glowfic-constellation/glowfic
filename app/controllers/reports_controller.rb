class ReportsController < ApplicationController
  def index
  end

  def show
    unless ['daily', 'monthly'].include?(params[:id])
      flash[:error] = "Could not identify the type of report."
      redirect_to reports_path
    end
  end
end
