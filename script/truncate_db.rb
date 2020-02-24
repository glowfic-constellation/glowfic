unless Rails.env.test?
    raise ArgumentError, "this script is only for use in a test environment!"
end

ActiveRecord::Base.connection.execute "TRUNCATE users CASCADE"
