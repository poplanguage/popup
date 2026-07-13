require "./test_helper"

class InstallerTest < Minitest::Test
  DOWNLOAD_URL  = "https://github.com/poplanguage/pop/releases/download/v0.1.0/pop-x86_64-unknown-linux-gnu.tar.gz"
  EXPECTED_FILE = "pop-x86_64-unknown-linux-gnu.tar.gz"

  def setup
    WebMock.reset
  end

  def teardown
    File.delete(EXPECTED_FILE) if File.exists?(EXPECTED_FILE)
    WebMock.reset
  end

  def test_install_downloads_correct_asset
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
      .to_return(body: release_body)

    WebMock.stub(:get, DOWNLOAD_URL)
      .to_return(body_io: IO::Memory.new("pop binary content"))

    Installer.new("v0.1.0").install

    assert File.exists?(EXPECTED_FILE)
    assert_equal "pop binary content", File.read(EXPECTED_FILE)
  end

  def test_install_skips_sha256_and_picks_binary
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
      .to_return(body: release_body_with_sha)

    WebMock.stub(:get, DOWNLOAD_URL)
      .to_return(body_io: IO::Memory.new("pop binary content"))

    Installer.new("v0.1.0").install

    assert File.exists?(EXPECTED_FILE)
  end

  def test_install_prints_error_when_asset_missing
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
      .to_return(body: release_body_no_match)

    Installer.new("v0.1.0").install

    refute File.exists?(EXPECTED_FILE)
  end

  def test_install_raises_on_http_error
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
      .to_return(body: "not found", status: 404)

    assert_raises { Installer.new("v0.1.0").install }
  end

  private def release_body
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-x86_64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => DOWNLOAD_URL,
        },
      ],
    }.to_json
  end

  private def release_body_with_sha
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-x86_64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => DOWNLOAD_URL,
        },
        {
          "name"                 => "pop-x86_64-unknown-linux-gnu.tar.gz.sha256",
          "browser_download_url" => DOWNLOAD_URL + ".sha256",
        },
      ],
    }.to_json
  end

  private def release_body_no_match
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-aarch64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => "https://github.com/nothing",
        },
      ],
    }.to_json
  end
end
