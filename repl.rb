require "./interpreter"

interp = Interpreter.new

loop do
  print "> "
  obj = $stdin.read_sexp
  if obj == Eof.instance
    puts ""
    break
  end
  puts interp.eval(obj).to_sexp
end
