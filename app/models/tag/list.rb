class Tag::List < Array
  def initialize(list=[])
    super
    clean_tags unless self == []
  end

  def clean_tags
    reject(&:blank?).map(&:to_s).uniq
  end
end
