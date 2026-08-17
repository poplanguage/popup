require "./spec_helper"

describe Installer do
  before_each { WebMock.reset }
  after_each { WebMock.reset }

  it "downloads the exact current-platform archive from the Pop Index" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL).to_return(body: InstallUtils.manifest.to_json)
    WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
      .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))

    installer = Installer.new(InstallUtils::TAG)
    result = installer.install

    File.read(result).should eq(InstallUtils::ARCHIVE_CONTENT)
    installer.version.should eq(InstallUtils::TAG)
  ensure
    FileUtils.rm_rf(File.dirname(result)) if result
  end

  it "uses the Index SHA-256 instead of a GitHub checksum sidecar" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL).to_return(body: InstallUtils.manifest.to_json)
    WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
      .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))

    Installer.new(InstallUtils::VERSION).install
  end

  it "rejects an archive whose digest differs from the manifest" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL)
      .to_return(body: InstallUtils.manifest([InstallUtils.artifact("0" * 64)]).to_json)
    WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
      .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))

    expect_raises(Exception, "checksum mismatch") { Installer.new(InstallUtils::VERSION).install }
  end

  it "refuses a release with no matching platform artifact" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL)
      .to_return(body: InstallUtils.manifest([InstallUtils.other_target_artifact]).to_json)

    expect_raises(Exception, "no available pop archive") { Installer.new(InstallUtils::VERSION).install }
  end

  it "refuses an artifact retained but unavailable from the Index" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL)
      .to_return(body: InstallUtils.manifest([InstallUtils.artifact(InstallUtils::ARCHIVE_SHA256, false)]).to_json)

    expect_raises(Exception, "no available pop archive") { Installer.new(InstallUtils::VERSION).install }
  end

  it "reports an Index HTTP failure" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL).to_return(body: "not found", status: 404)

    expect_raises(Exception, "Pop Index request failed (HTTP 404)") { Installer.new(InstallUtils::VERSION).install }
  end
end
