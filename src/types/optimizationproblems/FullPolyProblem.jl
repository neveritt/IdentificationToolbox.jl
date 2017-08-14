type FullPolyProblem{S,T,V1,V2,Tf,Tg,Th,M1,M2} <: AbstractNLPEvaluator
  data::IdDataObject{T,V1,V2}
  model::S
  options::IdOptions
  f::Tf
  g!::Tg
  h!::Th
  G::M1
  H::M2

  function (::Type{FullPolyProblem}){S<:PolyModel,T1,V1,V2}(
    data::IdDataObject{T1,V1,V2}, model::S, options::IdOptions=IdOptions())

    T = float(T1)
    x_seed = zeros(T, numparams(model,options))
    G = zeros(T, numparams(model,options))
    H = zeros(T, numparams(model,options), numparams(model,options))
    f = x-> cost(data, model, x, options)
    if options.autodiff == :finite
        function g!(storage::Vector, x::Vector)
            Calculus.finite_difference!(f, x, storage, :central)
            return
        end
        function h!(storage::Matrix, x::Vector)
            Calculus.finite_difference_hessian!(f, x, storage)
            return
        end
    elseif options.autodiff == :forward
        gcfg = ForwardDiff.GradientConfig(f, x_seed)
        g! = (out, x) -> ForwardDiff.gradient!(out, f, x, gcfg)
        hcfg = ForwardDiff.HessianConfig(f, x_seed)
        h! = (out, x) -> ForwardDiff.hessian!(out, f, x, hcfg)
    elseif options.autodiff == :reverse
        gcfg = ReverseDiff.GradientConfig(x_seed)
        g! = (out, x) -> ReverseDiff.gradient!(out, f, x, gcfg)
        hcfg = ReverseDiff.HessianConfig(x_seed)
        h! = (out, x) -> ReverseDiff.hessian!(out, f, x, hcfg)
    else
        error("The autodiff value $(autodiff) is not supported. Use :finite, :forward or :reverse.")
    end
    new{S,T,V1,V2,typeof(f),typeof(g!),typeof(h!),typeof(G),typeof(H)}(
    data,model,options,f,g!,h!,G,H)
  end
end

function initialize(d::FullPolyProblem, requested_features::Vector{Symbol})
    for feat in requested_features
        if !(feat in features_available(d))
            error("Unsupported feature $feat")
        end
    end
end

features_available(d::FullPolyProblem) = [:Grad, :Hess]

eval_f(d::FullPolyProblem, x) = d.f(x)

eval_g(d::FullPolyProblem, g, x) = nothing

eval_grad_f(d::FullPolyProblem, grad_f, x) = d.g!(grad_f,x)

function hesslag_structure(d::FullPolyProblem)
  n = numparams(d.model,d.options)
  I = Vector{Int}(convert(Int,(n*n-n)/2))
  J = Vector{Int}(convert(Int,(n*n-n)/2))
  k = 1
  for i in 1:n
    for j in i:n
      I[k] = i
      J[k] = j
      k   += 1
    end
  end
  (I,J)
end

function eval_hesslag(d::FullPolyProblem, H, x, σ, μ)
  d.h!(d.H,x)
  k = 1
  for i in 1:n
    for j in i:n
      H[k] = σ*d.H[i,j]
      k   += 1
    end
  end
end
