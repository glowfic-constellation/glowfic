class Generic::Saver < Generic::Service
  def initialize(model, user:, params:, allowed_params: [])
    @user = user
    @params = params
    @model = model
    @allowed = allowed_params if allowed_params.present?
    super()
  end

  def perform
    build
    save
  end

  alias_method :create, :perform
  alias_method :update, :perform

  private

  def build
    @model.assign_attributes(permitted_params)
  end

  def save
    return true if @model.save
    @errors.add(:base, "Your #{model.class.name.downcase} could not be saved because of the following errors:")
    @errors.merge!(@model.errors)
    false
  end

  def permitted_params
    @params.fetch(@model.class.name.underscore.to_sym, {}).permit(@allowed)
  end
end
