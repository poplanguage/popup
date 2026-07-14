require "spec"
require "webmock"
require "json"
require "crest"
require "file_utils"

require "../src/popup/version"
require "../src/popup/github"
require "../src/popup/utils/target"
require "../src/popup/installer"

include Popup

module InstallUtils
  extend self

  DOWNLOAD_URL = "https://github.com/poplanguage/pop/releases/download/v0.1.0/pop-x86_64-unknown-linux-gnu.tar.gz"

  EXPECTED_FILE = "pop-x86_64-unknown-linux-gnu.tar.gz"

  def release_with_binary
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-x86_64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => DOWNLOAD_URL,
        },
      ],
    }
  end

  def release_with_binary_and_sha
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
    }
  end

  def release_for_wrong_arch
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-aarch64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => "https://github.com/nothing",
        },
      ],
    }
  end
end
