class UserCreated
  def self.call
    File.exist?(node["chef_postgres"]["vars"]["admin_login_path"])
  end
end
