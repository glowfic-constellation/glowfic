class ApiError < StandardError
  def initialize(msg, error_array=nil)
    @msg = msg
    @error_array = error_array
    super(msg)
  end

  def api_error
    return @msg unless @error_array.present?
    {
      message: @msg,
      array: @error_array
    }
  end
end
