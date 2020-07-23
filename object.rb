require 'singleton'

class Eof
  include Singleton

  def to_sexp
    "#<eof>"
  end
end
