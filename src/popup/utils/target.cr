module Popup::Utils::Target
  extend self

  def current_arch : String
    `uname -i`.strip
  end

  def aarch64? : Bool
    current_arch.downcase == "aarch64"
  end

  def x86_64? : Bool
    current_arch.downcase == "x86_64"
  end

  def linux? : Bool
    {% if flag?(:linux) %}
      true
    {% else %}
      false
    {% end %}
  end

  def target_string : String
    if linux?
      if aarch64?
        "aarch64-unknown-linux-gnu"
      elsif x86_64?
        "x86_64-unknown-linux-gnu"
      else
        raise "unsupported architecture: #{current_arch}"
      end
    else
      raise "unsupported platform: only linux is supported"
    end
  end
end
