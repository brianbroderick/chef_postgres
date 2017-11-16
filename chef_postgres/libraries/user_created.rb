class UserCreated
  attr_reader :node

  def self.call(*args)
    new(*args).call
  end

  def initialize(node)
    @node = node
  end

  def call
    File.exist?(node["chef_postgres"]["vars"]["admin_login_path"])
  end
end
