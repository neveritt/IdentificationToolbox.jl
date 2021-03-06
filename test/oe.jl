println("Starting OE method test...")

# Define the true system
b = [0.1, 0.3, 0.2]
f = [0.5, 0.11, 0.05]

# model orders
nb, nf = 30, 30
nk = 1
n = [nb, nf, nk]

# intitial parameters
x = [b; zeros(nb-3);f; zeros(nf-3)]

# generate input data+noise and simulate output
B = [0;b]
F = [1;f]
N = 1000
u = randn(N)
lambda = 10
e = sqrt(lambda)*randn(N)
y = filt(B,F,u,[2.;2;2]) + e

# create iddataObject for the input/output data
data = iddata(y,u)

# test internal method
k = nb+nf
storage = zeros(Float64,k,k+1)
last_V = [-0.1]
V = IdentificationToolbox.gradhessian!(data, n, x, OE(), 0.9*x, last_V, storage)
@test abs(V-lambda) < 0.3*lambda

# test user methods
S = Array(IdDSisoRational,0)

# bj constructor
push!(S, oe(data, n, x))

# pem constructor
push!(S, pem(data, n, x, OE()))

for system in S
  @test abs(system.info.mse-lambda) < 0.3*lambda
end

using ForwardDiff

f5(x::Vector) = sum(sin, x) + prod(tan, x) * sum(sqrt, x)

function f1(x::Vector)
  return dot(x,x)
end

function f2(x::Vector)
  A = reshape(x, 2, 2)
  return trace(A*A)
end

function f3(x::Vector)
  y = x[1]
  y2 = x[2]
  return y*y2
end

using ForwardDiff
N = 100
nb = nf = 2
ny = nu = 2
nk = 1
m  = ny*nf+nu*nb
x  = randn(m*ny)
xr = reshape(x[1:m*ny], m, ny)
xf = _blocktranspose(view(xr, 1:ny*nf, :), ny, ny, nf)
F  = PolyMatrix(vcat(eye(Float64,ny), xf), (ny,ny))
B  = PolyMatrix(vcat(zeros(Float64,ny*nk[1],nu), xf), (ny,nu))

u = randn(nu,N)


filt(B, F, u)

function f4(x::Vector, u)
  N  = 100
  ny = ny = 2
  m  = ny*nf+nu*nb

  xr = reshape(x[1:m*ny], m, ny)
  xf = _blocktranspose(view(xr, 1:ny*nf, :), ny, ny, nf)
  F  = PolyMatrix(vcat(eye(Float64,ny), xf), (ny,ny))
  B  = PolyMatrix(vcat(zeros(Float64,ny*nk[1],nu), xf), (ny,nu))
  sumabs2(filt(B, F, u) - ones(u))
end

f4(x,u)
f5 = x->f4(x,u)

g = x -> ForwardDiff.gradient(f5, x)
g(x)

function f2(x::Vector, u)
  A = reshape(x[1:4], 2, 2)
  B = reshape(x[5:8], 2, 2)
  return sumabs2(A*B)
end

x = randn(8)
f6 = x->f2(x,u)
g = x -> ForwardDiff.gradient(f6, x)
g(x)

using Polynomials, Optim, PolynomialMatrices, LTISystems, ToeplitzMatrices, GeneralizedSchurAlgorithm
#, Compat
using ForwardDiff
A = zeros(ForwardDiff.Dual{10,Float64}, 2, 2)
b = zeros(ForwardDiff.Dual{10,Float64}, 2)
A * b


x = rand(5)
g = x -> ForwardDiff.gradient(f5, x)
g(x)

g1 = x -> ForwardDiff.gradient(f1, x)
x = randn(4)
g1(x)

g2 = x -> ForwardDiff.gradient(f2, x)
x = randn(4)
g2(x)

g3 = x -> ForwardDiff.gradient(f3, x)
x = randn(8)
g3(x)




b = [0.3]
f = [0.5]

B = [0; b]
F = [1; f]

nb = nf = 3

N  = 200
u1 = randn(N)
u2 = randn(N)
lambda = 0.1
e1 = sqrt(lambda)*randn(N)
e2 = sqrt(lambda)*randn(N)
y1 = filt(B,F,u1) + 0.1*filt(B, [1, 0.2, 0.1],u2) + filt([1.,0.1], [1, 0.7], e1)
y2 = 0.1*filt(B,F,u1) + filt(B,F,u2) + filt([1.,0.1], [1, 0.7], e2)

u = hcat(u1,u2).'
y = hcat(y1).'
data2 = iddata(y, u)

nu = size(u,1)
ny = size(y,1)
nk = ones(Int,nu)

model = OE(nb,nf,nk,ny,nu)
model2 = OE(nb,nf,[1],ny,nu)
orders(model)
model.orders[1,1]
model[:,1]

m = nf*ny^2+nb*nu*ny
randn(m)
m0 = max(nb,nf)*ny

@time predict(data2, model, randn(m+m0))
cost(data2, model, randn(m+m0))
_mse(data2, model, randn(m+m0))

typeof(model)
psi = psit(data2, model, randn(m+m0))
orders(model)

x0 = vcat(b[1]*ones(nu,ny), zeros((nb-1)*nu,ny), f[1]*eye(ny), zeros((nf-1)*ny,ny))[:]
#x0 = vcat(b[1]*ones(nu,ny), b[2]*ones(nu,ny), b[3]*ones(nu,ny), f[1]*eye(ny), f[2]*eye(ny), f[3]*eye(ny))[:]
x0 = vcat(x0,zeros(m0))

options = IdOptions(extended_trace=false, iterations = 100, autodiff=true, show_trace=true, estimate_initial=false)
cost(data2, model, x0, options)

@time sys1 = pem(data2, model, x0 + 0.1*randn(length(x0)), options) # , IdOptions(f_tol = 1e-32)
B1 = sys1.B
F1 = sys1.F
sys1.info.opt
sys1.info.mse
fieldnames(sys1.info.opt.trace[1].metadata)
sys1.info.opt.trace[1]

options2 = IdOptions(f_tol=1e-64, extended_trace=false, iterations = 1, autodiff=true, show_trace=true, estimate_initial=false)
#_stmcb(data2,model,options2)
@time sys2 = stmcb(data2,model,options2)
B2 = sys2.B
F2 = sys2.F
sys2.info.mse


@time x,pe = _morsm(data2,model,options2)
Bm = PolyMatrix(hcat([Poly(vcat(zeros(1),x[1:nb]))]))
Fm = PolyMatrix(hcat([Poly(vcat(ones(1),x[nb+(1:nf)]))]))

uz    = zeros(nu,100)
uz[1] = 1.0
g1 = filt(B1,F1,uz)
g2 = filt(B2,F2,uz)
gm = filt(Bm,Fm,uz)
gt = filt(B,F,uz.').'

norm(g1-gt)/norm(gt)
norm(g2-gt)/norm(gt)
norm(gm-gt)/norm(gt)


bjmodel = BJ(nb,nf,0,m,nk,ny,nu)
a,b,f,c,d = _getpolys(bjmodel, xb)
xb  = vcat(x[1:nb+nf], xaₗ) |> vec
predict(data2, bjmodel, xb, options2)
y
pe  = cost(data2, bjmodel, xb, options2)
pe  = cost(data2, bjmodel, xb, options2)


Aₗ
uz    = zeros(nu,100)
uz[1] = 1.0
g2 = filt(Bₗ,Aₗ,uz)
g1 = filt(B,F,uz)
gt = filt(B,F,uz)



# High order models to test filter
minorder  = convert(Int,max(floor(N/1000),2*(nb+nf)))
maxorder  = convert(Int,min(floor(N/20),40))
orderh    = maxorder+10
nbrorders = min(10, maxorder-minorder)
ordervec  = convert(Array{Int},round(linspace(minorder, maxorder, nbrorders)))


# Model for cost function evaluation using orderh noise model
if 1 == 1 # only G implemented first
  bjmodel = BJ(nb,nf,0,orderh,1,ny,1)
else # version == :H
  bjmodel = BJ(nb,nf,nc,nd,nk,ny,nu)
end

# OE model for STMCB
Gmodel = OE(nb,nf,1,ny,1)

data = data2
# High-order model used for high order noise model
modelₕ = ARX(orderh, orderh, nk, ny, nu)
Θₕ, peharx = _arx(data2, modelₕ, options)
mₕ  = ny*orderh+nu*orderh
xr  = reshape(Θₕ[1:mₕ*ny], mₕ, ny)
xaₕ = view(xr, 1:ny*orderh, :)
Aₕ  = PolyMatrix(vcat(eye(ny), _blocktranspose(xaₕ, ny, ny, orderh)), (ny,ny))

# filtered data
yf = similar(y)
uf = similar(u)
dataf = iddata(yf, uf, data.Ts)

mₗ = nu*ny*(nb+nf)
bestx   = zeros(mₗ)
bestpe  = typemax(Float64)

m = 20

modelₗ = ARX(m, m, nk, ny, nu)
Θₗ  = _arx(data, modelₗ, options)[1]
xr  = reshape(Θₗ, ny*m+nu*m, ny) # [1:(ny*m+nu*m)*ny]
xaₗ = view(xr, 1:ny*m, :)
xbₗ = view(xr, ny*m+(1:nu*m), :)
Aₗ  = PolyMatrix(vcat(eye(ny),      _blocktranspose(xaₗ, ny, ny, m)), (ny,ny))
Bₗ  = PolyMatrix(vcat(zeros(ny,nu), _blocktranspose(xbₗ, ny, nu, m)), (ny,nu))

u1 = zeros(1,N)
_filt_fir!(u1, Aₗ, u[1:1,:])
u2 = zeros(1,N)
_filt_fir!(u2, Aₗ, u[2:2,:])

y1 = zeros(1,N)
_filt_fir!(y1, PolyMatrix(Bₗ[1:1,1:1]), u[1:1,:])
y2 = zeros(1,N)
_filt_fir!(y2, PolyMatrix(Bₗ[1:1,2:2]), u[2:2,:])

yh = similar(y)
_filt_fir!(yh, Aₗ, y)

y1f = yh - y2
y2f = yh - y1


dataf1 = iddata(y1,u1,data.Ts)
datav1 = iddata(y,u[1:1,:],data.Ts)
ΘG = _stmcb(dataf1, Gmodel, options)
xg = reshape(ΘG, nb+nf, ny)
x  = vcat(xg, xaₕ) |> vec
x1 = x[1:nb+nf]
pe = cost(datav1, bjmodel, x, options)
a,b1,f1,c,d          = _getpolys(Gmodel, x)

dataf2 = iddata(y2,u2,data.Ts)
datav2 = iddata(y,u[2:2,:],data.Ts)
ΘG = _stmcb(dataf2, Gmodel, options)
xg = reshape(ΘG, nb+nf, ny)
x  = vcat(xg, xaₕ) |> vec
x2 = x[1:nb+nf]
pe = cost(datav2, bjmodel, x, options)
a,b2,f2,c,d          = _getpolys(Gmodel, x)

yhat = filt(b1,f1,u[1:1,:]) + filt(b2,f2,u[2:2,:])
sumabs2(y-yhat)/N

x0n = vcat(x1[1:nb], x2[1:nb], x1[nb+(1:nf)], x2[nb+(1:nf)])

Morders = MPolyOrder(zeros(Int,1,1), nb*ones(Int,ny,nu), nf*ones(Int,ny,nu), zeros(Int,ny,ny), zeros(Int,ny,ny), ones(Int,ny,nu))
Mmodel = PolyModel(Morders, ny, nu, ControlCore.Siso{false}, CUSTOM)

cost(data2, Mmodel, x0n, options)
@time sys2 = pem(data2, Mmodel, x0n, options) # , IdOptions(f_tol = 1e-32)
B1 = sys1.B
F1 = sys1.F
sys1.info.opt
sys1.info.mse
fieldnames(sys1.info.opt.trace[1].metadata)
sys1.info.opt.trace[1]

data2.nu
_morsm_yi(data2,Mmodel,options)

nA,nB,nF,nC,nD,nk = orders(Mmodel)
convert(Int, max(floor(N/1000), 2*(maximum(nB[1,:]) + maximum(nF[1,:])) ))

maxorder  = convert(Int, min(floor(N/20),40))
orderh    = maxorder+10
nbrorders = min(10, maxorder-minorder)
ordervec  = convert(Array{Int},round(linspace(minorder, maxorder, nbrorders)))

Mmodel.orders
MPolyOrder(na[i:i,:],)
# High-order model used for high order noise model
modelₕ = ARX(orderh*ones(Int,ny,ny), orderh*ones(Int,ny,nu), nk)

uz    = zeros(1,100)
uz[1] = 1.0
g1 = filt(PolyMatrix(B1[1:1,1:1]),F1,uz)
g2 = filt(PolyMatrix(B1[1:1,2:2]),F1,uz)
gf1 = filt(b1,f1,uz)
gf2 = filt(b2,f2,uz)
gt = filt(B,F,uz.').'

norm(g1-gt)/norm(gt)
norm(g2-0.1*gt)/norm(gt)
norm(gf1-gt)/norm(gt)
norm(gf2-0.1*gt)/norm(gt)

out = zeros(y)
@time _filt_fir!(out,b,y)
filt!(out,b,f,u1)
out
b
y1
y2 = randn(1,N)
out2 = similar(y2)
@time _filt_fir!(out2,b,y2)

uf = similar(u)
@time _filt_fir!(uf, Aₗ, u)

bjmodel = BJ(nb,nf,0,12,1,ny,nu)


x2 = vcat(x0[1],x0[2], zeros(12))
cost(data2,bjmodel,x[:],options2)
cost(data2,model,x2,options2)
_mse(data2,model,x0[1:2],options2)

uz    = zeros(nu,100)
uz[1] = 1.0
g2 = filt(sys2.B,sys2.F,uz)
g1 = filt(B,F,uz).'
gt = filt(B,F,uz)



b2 = zeros(ny,nu*nb)
for i = 1:nb
  b2[:,(i-1)*nu+(1:nu)] = sys2.B.coeffs[i][:,:].'
end
f2 = zeros(ny,ny*nf)
for i = 1:nf
  f2[:,(i-1)*ny+(1:ny)] = sys2.F.coeffs[i][:,:].'
end
x02 = vcat(b2.',f2.')[:]

sumabs2(g1-gt)
sumabs2(g2-gt)
norm(g2-gt)
norm(g1-gt)

@time sys1 = pem(data2, model, x02, options) # , IdOptions(f_tol = 1e-32)
@time sys1 = pem(data2, model, sys1.info.opt.minimizer, options)
sys1.B
sys1.F
sys1.info.opt
sys1.info.mse

sys.info.opt.trace[1].metadata.vals

options.OptimizationOptions.iterations

df = TwiceDifferentiableFunction(x->cost(data2, model, x0, options))
stor = zeros(2m,2m)
a = df.h!(x0,stor)
df

k = length(x0) # number of parameters
last_x  = zeros(Float64,k)
last_V  = -ones(Float64,1)
storage = zeros(k, k+1)
g = x0
@time gradhessian!(data2, model, x0, last_x, last_V, storage, options)
g = storage[:,end]
H = storage[:,1:end-1]
H\g
x = x0-0.0001*(H\g)

gradhessian!(data2, model, x, last_x, last_V, storage, options)
g = storage[:,end]
H = storage[:,1:end-1]+eye(k)*0.0001
x = x-0.1*(H\g)

psi = psit(data2, model, x, options)
psi.'*psi/N

@time y_est = predict(data2, model, x0)
predict(data2, model, x0)



model = OE(1,1,[1],ny,nu)
orders(model)
x0 = vcat(f[1]*ones(nu,ny), b[1]*eye(ny), 0.1*eye(ny))[:]
m = length(x0)

options = IdOptions(f_tol=1e-64, extended_trace=false, iterations = 100, autodiff=false, show_trace=true, estimate_initial=false)
@time sys = pem(data2, model, x0+0.05*randn(m))
sys.F
sys.B
sys.info.opt

sys = stmcb(data2,model)
_stmcb(data2, model, options)

options.OptimizationOptions.iterations


b = [0.3]
f = [0.5]

B = [0;b]
F = [1;f]

nb = nf = 10

N  = 200
u1 = 1*randn(N)
u2 = 1*randn(N)
lambda = 0.1
e1 = sqrt(lambda)*randn(N)
e2 = sqrt(lambda)*randn(N)
y1 = filt(B,F,u1) + 0.*filt(B,F,u2) + e1
y2 = 0.1*filt(B,F,u1) + filt(B,F,u2) + e2

u = hcat(u1,u2)
y = hcat(y1)
data2 = iddata(y, u)

ny = size(y,2)
nu = size(u,2)


mna = ones(Int,ny,ny)
mnb = 5*ones(Int,ny,nu)
mnf = 5*ones(Int,ny,nu)
mnc = 2*ones(Int,ny)
mnd = 2*ones(Int,ny)
mnk = ones(Int,ny,nu)
order = MPolyOrder(mna,mnb,mnf,mnc,mnd,mnk)
model = PolyModel(order, ny, nu, ControlCore.Siso{false}, CUSTOM)
nparam = sum(mna) + sum(mnb) + sum(mnf) + sum(mnc) + sum(mnd)
x = zeros(nparam)
x[1] = x[5] = 0.2
x[9] = x[13] = 0.4

x
sum(mnf)

predict(data2,model,x)
cost(data2,model,x)

options2 = IdOptions(f_tol=1e-64, extended_trace=false, iterations = 10, autodiff=true, show_trace=true, estimate_initial=false)
@time sys2 = pem(data2,model,x,options2)
sys2.info.opt
sys2.info.mse
sys2.B
sys2.F
