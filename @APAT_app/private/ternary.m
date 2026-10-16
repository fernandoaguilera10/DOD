function out = ternary(cond, a, b)
%TERNARY  Inline conditional: if cond is true return a, else return b.
if cond, out = a; else, out = b; end
end
