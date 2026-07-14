require "../spec_helper"

describe Utils::Target do
  it "current arch returns a string" do
    arch = Utils::Target.current_arch

    arch.is_a?(String).should be_true
    arch.empty?.should be_false
  end

  it "arch detection is mutually exclusive" do
    aarch64 = Utils::Target.aarch64?
    x86_64 = Utils::Target.x86_64?

    (aarch64 || x86_64).should be_true
    (aarch64 && x86_64).should be_false
  end

  it "returns a target string in the expected format" do
    target = Utils::Target.target_string
    target.should match(/^(x86_64|aarch64)-unknown-linux-gnu$/)
  end
end
