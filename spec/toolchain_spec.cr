require "./spec_helper"

describe Toolchain do
  it "writes a shim for the configured POPUP_HOME instead of hard-coding HOME" do
    root = File.tempname("popup-toolchain-spec")
    toolchain = Toolchain.new(root)
    version_dir = File.join(toolchain.toolchains_dir, "v0.1.0")
    Dir.mkdir_p(version_dir)

    toolchain.install("v0.1.0", Utils::Target.target_string)

    shim = File.read(toolchain.shim_path)
    shim.should contain(File.join(root, "toolchains", "default"))
    shim.should_not contain("$HOME/.popup")
  ensure
    FileUtils.rm_rf(root) if root
  end
end
