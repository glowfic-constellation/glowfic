module DateSelectable
  private

  def calculate_day
    return Time.zone.now.to_date unless params[:day].present?

    begin
      params[:day].in_time_zone(Time.zone).to_date

    # invalid time stamps processed with .in_time_zone return nil and raise NoMethodError
    # whereas out of range timestamps like January 32nd raise ArgumentError
    rescue NoMethodError, ArgumentError
      Time.zone.now.to_date
    end
  end
end
