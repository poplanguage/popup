require "../test_helper"

class TargetTest < Minitest::Test
  def test_current_arch_returns_nonempty_string
    arch = Utils::Target.current_arch

    assert arch.is_a?(String)
    assert arch.size > 0, "uname -i returned empty string"
  end

  def test_arch_detection_is_mutually_exclusive
    aarch64 = Utils::Target.aarch64?
    x86_64 = Utils::Target.x86_64?

    assert (aarch64 || x86_64), "expected one arch check to pass"
    refute (aarch64 && x86_64), "both arch checks passed, but only one should"
  end
end
