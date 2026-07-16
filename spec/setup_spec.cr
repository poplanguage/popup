require "./spec_helper"

describe Installer::Setup do
  it "installs a complete bundle with executable and data file permissions" do
    root = File.tempname("popup-setup-spec")
    Dir.mkdir_p(root)
    archive = File.join(root, "toolchain.zip")
    target = Utils::Target.target_string
    binary = "pop-#{target}"
    language_server = "pop-language-server-#{target}"
    InstallUtils.write_toolchain_archive(archive, {
      binary                    => "binary",
      language_server           => "language server",
      "libpop_standard.a"       => "standard",
      "libpop_runtime_native.a" => "runtime",
    })

    toolchains = File.join(root, "toolchains")
    Installer::Setup.new("v0.1.0", archive, toolchains, target).run

    version = File.join(toolchains, "v0.1.0")
    (File.info(File.join(version, binary)).permissions.value & 0o111).should eq(0o111)
    (File.info(File.join(version, language_server)).permissions.value & 0o111).should eq(0o111)
    (File.info(File.join(version, "libpop_standard.a")).permissions.value & 0o111).should eq(0)
    File.exists?(archive).should be_false
  ensure
    FileUtils.rm_rf(root) if root
  end

  it "requires the official language server in a complete toolchain bundle" do
    root = File.tempname("popup-setup-spec")
    Dir.mkdir_p(root)
    archive = File.join(root, "toolchain.zip")
    target = Utils::Target.target_string
    InstallUtils.write_toolchain_archive(archive, {
      "pop-#{target}"           => "binary",
      "libpop_standard.a"       => "standard",
      "libpop_runtime_native.a" => "runtime",
    })

    expect_raises(Exception, "missing required toolchain file: pop-language-server-#{target}") do
      Installer::Setup.new("v0.1.0", archive, File.join(root, "toolchains"), target).run
    end
  ensure
    FileUtils.rm_rf(root) if root
  end

  it "rejects archive entries that escape the toolchain directory" do
    root = File.tempname("popup-setup-spec")
    Dir.mkdir_p(root)
    archive = File.join(root, "toolchain.zip")
    InstallUtils.write_toolchain_archive(archive, {"../escaped" => "bad"})

    expect_raises(Exception, "unsafe archive entry") do
      Installer::Setup.new("v0.1.0", archive, File.join(root, "toolchains"), Utils::Target.target_string).run
    end
    File.exists?(File.join(root, "escaped")).should be_false
  ensure
    FileUtils.rm_rf(root) if root
  end

  it "requires a complete Pop Lang toolchain bundle" do
    root = File.tempname("popup-setup-spec")
    Dir.mkdir_p(root)
    archive = File.join(root, "toolchain.zip")
    binary = "pop-#{Utils::Target.target_string}"
    InstallUtils.write_toolchain_archive(archive, {binary => "binary"})

    expect_raises(Exception, "missing required toolchain file") do
      Installer::Setup.new("v0.1.0", archive, File.join(root, "toolchains"), Utils::Target.target_string).run
    end
    Dir.children(File.join(root, "toolchains")).should be_empty
  ensure
    FileUtils.rm_rf(root) if root
  end
end
