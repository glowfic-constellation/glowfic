class ChangeTimestampsToUtc < ActiveRecord::Migration[4.2]
  TABLES = {
    audits: [:created_at],
    board_authors: [:created_at, :updated_at],
    board_sections: [:created_at, :updated_at],
    board_views: [:created_at, :updated_at, :read_at],
    boards: [:created_at, :updated_at],
    character_aliases: [:created_at, :updated_at],
    character_tags: [:created_at, :updated_at],
    characters: [:created_at, :updated_at],
    favorites: [:created_at, :updated_at],
    flat_posts: [:created_at, :updated_at],
    galleries: [:created_at, :updated_at],
    gallery_tags: [:created_at, :updated_at],
    icons: [:created_at, :updated_at],
    messages: [:read_at, :created_at, :updated_at],
    password_resets: [:created_at, :updated_at],
    post_tags: [:created_at, :updated_at],
    post_viewers: [:created_at, :updated_at],
    post_views: [:created_at, :updated_at, :read_at],
    posts: [:created_at, :updated_at, :edited_at, :tagged_at],
    replies: [:created_at, :updated_at],
    reply_drafts: [:created_at, :updated_at],
    report_views: [:read_at, :created_at, :updated_at],
    tags: [:created_at, :updated_at],
    templates: [:created_at, :updated_at],
    users: [:created_at, :updated_at]
  }

  def fetch_zone
    zone_name = Time.now.zone # GMT, BST, etc.
    # this list is likely overkill
    zone_maps = {
      "UTC" => ["UTC"],
      "Europe/London" => ["GMT", "BST"],
      "America/New_York" => ["EST", "EDT"],
      "America/Chicago" => ["CST", "CDT"],
      "America/Denver" => ["MST", "MDT"], # sorry Phoenix
      "America/Los_Angeles" => ["PST", "PDT"],
      "Europe/Paris" => ["CET", "CEST"], # there is no general Europe one?
      "Europe/Lisbon" => ["WET", "WEST"],
      "America/Sao_Paulo" => ["-02", "-03"] # may get false positives, but we don't have many Brazilians
      # no Australians etc probably?
      # none who are actively developing at least and
      # this migration will become outdated but unnecessary
    }
    zone_maps.each do |olson, zones|
      return olson if zones.include?(zone_name)
    end
    raise("Failed to map timezone to region.")
  end

  def sql_for_migrate(table_name, cols, from_zone, to_zone)
    sql = "UPDATE #{table_name} SET "
    sql += cols.map do |col|
      "#{col}=((#{col} AT TIME ZONE '#{from_zone}') AT TIME ZONE '#{to_zone}')"
    end.join(', ')
    sql += ';'
    sql
  end

  def up
    local_zone = fetch_zone
    target_zone = 'UTC'
    if local_zone == target_zone
      say "Skipping migration as local_zone (#{local_zone}) matches target_zone (#{target_zone})"
      return
    end
    TABLES.each do |table_name, cols|
      execute sql_for_migrate(table_name, cols, local_zone, target_zone)
    end
  end

  def down
    local_zone = fetch_zone
    target_zone = 'UTC'
    if local_zone == target_zone
      say "Skipping migration as local_zone (#{local_zone}) matches target_zone (#{target_zone})"
      return
    end
    TABLES.reverse_each do |table_name, cols|
      execute sql_for_migrate(table_name, cols, target_zone, local_zone)
    end
  end
end
