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

  def windows? : Bool
    {% if flag?(:win32) %}
      true
    {% else %}
      false
    {% end %}
  end
end
