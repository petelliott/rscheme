require "./interpreter"

interp = Interpreter.new

loop do
  print "> "
  puts interp.eval($stdin.read_sexp).to_sexp
end
