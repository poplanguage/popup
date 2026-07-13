require "./test_helper"

class GitHubTest < Minitest::Test
  def setup
    WebMock.reset
  end

  def test_lastest_release_tag_from_single_release
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
      .to_return(body: [{"tag_name" => "v0.1.0"}].to_json)

    tag = GitHub.lastest_release_tag

    assert_equal "v0.1.0", tag
  end

  def test_lastest_release_tag_returns_first_release
    releases = [
      {"tag_name" => "v0.2.0"},
      {"tag_name" => "v0.1.0"},
    ]

    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
      .to_return(body: releases.to_json)

    tag = GitHub.lastest_release_tag

    assert_equal "v0.2.0", tag
  end

  def test_lastest_release_tag_raises_on_empty_releases
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
      .to_return(body: "[]")

    assert_raises { Popup::GitHub.lastest_release_tag }
  end

  def test_lastest_release_tag_raises_on_malformed_json
    WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
      .to_return(body: "not json")

    assert_raises { GitHub.lastest_release_tag }
  end
end
