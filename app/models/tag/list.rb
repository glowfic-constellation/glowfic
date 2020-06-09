class Tag::List < Array
  def initialize(list=[])
    super
    clean_tags unless self == []
    self
  end

  def clean_tags
    reject!(&:blank?)
    map!(&:to_s)
    map! { |name| name.start_with?('_') ? name[1..] : name }
    uniq!(&:downcase)
  end
end
