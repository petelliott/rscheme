require "stringio"
require "./object"

module Sexp
  module IO
    def read_sexp
      return Eof.instance if !(drain_ws)
      case peek
      when nil then Eof.instance
      when "("  then sexp_read_cons
      when "\"" then sexp_read_string
      when "#" then sexp_read_hash
      else
        tok = sexp_read_tok
        case tok
        when /^[+-]?\d+$/      then tok.to_i
        when /^[+-]?\d+\.\d+$/ then tok.to_f
        else tok.to_sym
        end
      end
    end

    private

    def peek
      ch = getc
      if ch
        ungetc(ch)
        ch
      end
    end

    def drain_ws
      each_char do |ch|
        if /^\S/ === ch
          ungetc(ch)
          return ch
        end
      end
      nil
    end


    def assert_next_char (ch)
      rch = getc
      raise "expected #{ch.inspect} got #{rch.inspect}" if rch != ch
    end

    def sexp_read_cdr_cons
      drain_ws
      case peek
      when ")"
        getc
        nil
      when "."
        getc
        val = read_sexp
        drain_ws
        assert_next_char ')'
        val
      else
        Sexp::Cons.new(read_sexp, sexp_read_cdr_cons)
      end
    end

    def sexp_read_cons
      assert_next_char '('
      sexp_read_cdr_cons
    end

    def sexp_read_tok
      str = ""
      each_char do |ch|
        case ch
        when /^[\(\)\s]$/
          ungetc(ch)
          break
        else
          str << ch
        end
      end
      str
    end

    def sexp_read_string
      str = getc
      each_char do |ch|
        str << ch;
        case ch
        when '\\'
          str << getc
        when '"'
          break
        end
      end
      str.undump
    end

    def sexp_read_hash
      assert_next_char '#'
      tok = sexp_read_tok
      case tok
      when "t"
        true
      when "f"
        false
      else
        raise "unrecognised hash sequence"
      end
    end

  end


  class Cons
    attr_reader :car, :cdr
    include Enumerable

    def initialize(car, cdr)
      @car, @cdr = car, cdr
    end

    def inspect
      "(#{@car.inspect} . #{@cdr.inspect})"
    end

    def to_s
      to_sexp
    end

    def to_sexp
      "(#{inner_to_sexp})"
    end

    def each
      cur = self
      while cur.class == Cons
        yield cur.car
        cur = cur.cdr
      end
    end

    protected

    def inner_to_sexp
      if @cdr == nil
        "#{@car.to_sexp}"
      elsif @cdr.class == Cons
        "#{@car.to_sexp} #{@cdr.inner_to_sexp}"
      else
        "#{@car.to_sexp} . #{@cdr.to_sexp}"
      end
    end
  end
end

class IO
  include Sexp::IO
end

class StringIO
  include Sexp::IO
end

class String
  def read_sexp
    StringIO.new(self).read_sexp
  end
end

class << nil
  def to_sexp
    "()"
  end
end

class Object
  def to_sexp
    inspect
  end
end

class Symbol
  def to_sexp
    to_s
  end
end

class Array
  def to_sexp
    str = map do |s|
      s.to_sexp
    end.join(" ")
    "#(#{str})"
  end
end

class TrueClass
  def to_sexp
    "#t"
  end
end

class FalseClass
  def to_sexp
    "#f"
  end
end
