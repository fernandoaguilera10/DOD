function [thr, p] = mx_sigfit(x, y)
%MX_SIGFIT  4-parameter sigmoid fit and 10 % threshold (same rule as ART).
% 4-parameter sigmoid y0 + L ./ (1 + exp(-k (x - x0))) fitted by least
% squares (fminsearch on transformed parameters: L, k >= 0, x0 within the
% levels); threshold where it reaches 10 % of its range (as ART).
thr = NaN;  p = nan(1, 4);
x = double(x(:)');  y = double(y(:)');
ok = isfinite(x) & isfinite(y);  x = x(ok);  y = y(ok);
if numel(y) < 4 || max(y) - min(y) <= 0, return; end
lo = min(x);  hi = max(x);
y0 = min(y);  L0 = max(y) - min(y);
unpack = @(q) [q(1), exp(q(2)), 2 ./ (1 + exp(-q(3))), lo + (hi - lo) ./ (1 + exp(-q(4)))];
model  = @(pp, xx) pp(1) + pp(2) ./ (1 + exp(-pp(3) * (xx - pp(4))));
cost   = @(q) sum((model(unpack(q), x) - y).^2);
best = [];  bc = inf;
for x0s = [0.35 0.6 0.85]
    xn = x0s;  q0 = [y0, log(max(L0, eps)), -log(2/0.15 - 1), log(xn / (1 - xn))];
    try
        q = fminsearch(cost, q0, optimset('Display','off', 'MaxFunEvals',4000, 'MaxIter',4000));
        cq = cost(q);
        if cq < bc, bc = cq;  best = q; end
    catch
    end
end
if isempty(best), return; end
p = unpack(best);
if p(2) <= 0 || p(3) <= 0, return; end
yt = p(1) + 0.10 * p(2);
thr = p(4) - (1 / p(3)) * log(p(2) / (yt - p(1)) - 1);
if ~isfinite(thr) || ~isreal(thr), thr = NaN; end
end
