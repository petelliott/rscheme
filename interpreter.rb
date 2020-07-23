require "./sexp"
require "set"

class Scope
  def initialize(parent=nil)
    @parent = parent
    @hash = Hash.new
  end

  def [](idx)
    if @hash.include? idx
      @hash[idx]
    elsif @parent == nil
      nil
    else
      @parent[idx]
    end
  end

  def []=(idx, val)
    @hash[idx] = val
  end

  def include?(idx)
    if @hash.include? idx
      true
    elsif @parent == nil
      false
    else
      @parent.include? idx
    end
  end

  def nest
    self.class.new(self)
  end
end


class Builtin
  @@builtins = Set[:cons, :car, :cdr, :+]
  def initialize(sym)
    raise "no such builtin #{sym}" if !(@@builtins.include? sym)
    @sym = sym
  end

  def self.add_all_to_scope(scope)
    @@builtins.each do |sym|
      scope[sym] = self.new(sym)
    end
  end

  def call(*args)
    send(@sym, *args)
  end

  def cons(car, cdr)
    Sexp::Cons.new(car, cdr)
  end

  def car(cons)
    cons.car
  end

  def cdr(cons)
    cons.cdr
  end

  def +(a, b)
    a + b
  end

end

class Interpreter
  @@specials = Set[:define, :if, :quote, :lambda, :set!]

  def initialize(scope=Scope.new, builtins=true)
    @scope = scope
    if builtins
      Builtin.add_all_to_scope(@scope)
    end
  end

  def [](idx)
    @scope[idx]
  end

  def []=(idx,val)
    @scope[idx] = val
  end

  def nest
    Interpreter.new(@scope.nest)
  end

  def eval(obj)
    case obj
    when Symbol
      if @scope.include? obj
        @scope[obj]
      else
        raise "unbound variable #{obj}"
      end
    when Sexp::Cons
      if obj.car.is_a? Symbol and @@specials.include? obj.car
        send(obj.car, *obj.cdr.to_a)
      else
        eval(obj.car).call(
          *(obj.cdr.to_a.map do |obj|
              eval(obj)
            end))
      end
    else
      obj
    end
  end

  def quote(obj)
    obj
  end

  class Closure
    def initialize(interpreter, lambda_list, body)
      @interp = interpreter
      @lambda_list = lambda_list
      @body = body
    end

    def call(*args)
      ninterp = @interp.nest
      if @lambda_list
        @lambda_list.zip(args).each do |name, val|
          ninterp[name] = val
        end
      end

      ret = nil
      @body.each do |expr|
        ret = ninterp.eval(expr)
      end
      ret
    end

    def to_sexp
      "#<closure #{object_id}>"
    end
  end

  def lambda(llist, *body)
    Closure.new(self, llist, body)
  end

  def define(ll_or_sym, *body)
    case ll_or_sym
    when Symbol
      raise "wrong number of args to value define" if body.length != 1
      self[ll_or_sym] = eval(body[0])
    when Sexp::Cons
      self[ll_or_sym.car] = Closure.new(self, ll_or_sym.cdr, body)
    else
      raise "invalid name argument to define"
    end
  end

  def set!(sym, val)
    raise "can't set! non-symbol #{sym}" if !(sym.is_a? Symbol)
    raise "set!: #{sym} is unbound" if !(@scope.include? sym)
    @scope[sym] = val
  end
end
