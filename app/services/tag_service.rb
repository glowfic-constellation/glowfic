class TagService
  def self.search(type, query)
    return _tag_search(query) if type.blank?
    return _setting_search(query) if type == 'setting'
    return _warning_search(query) if type == 'warning'
    []
  end

  private

  def self._tag_search(query)
    Tag.where("name LIKE ?", query.to_s + '%').where(type: nil)
  end

  def self._setting_search(query)
    Setting.where("name LIKE ?", query.to_s + '%')
  end

  def self._warning_search(query)
    ContentWarning.where("name LIKE ?", query.to_s + '%')
  end
end
