class Popup::CLI::Update
  def self.register(cmd)
    cmd.subcommand("update", "Install and select the latest Pop toolchain") do |update|
      update.run { Install.install }
    end
  end
end
