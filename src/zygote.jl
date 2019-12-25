function ZygoteRules.@adjoint ODESolution(u,args...)
  function ODESolutionAdjoint(ȳ)
    (ȳ,ntuple(_->nothing, length(args))...)
  end
  ODESolution(u,args...), ODESolutionAdjoint
end

ZygoteRules.@adjoint function ODESolution{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11
                }(u,args...) where {T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11}

                function ODESolutionAdjoint(ȳ)
                  (ȳ,ntuple(_->nothing, length(args))...)
                end

                ODESolution{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11}(u,args...),ODESolutionAdjoint
end

ZygoteRules.@adjoint function getindex(sol::DESolution, i)
  function DESolution_getindex_adjoint(Δ)
    Δ′ = Union{Nothing, eltype(sol.u)}[nothing for x in sol.u]
    Δ′[i] = Δ
    (Δ′,nothing)
  end
  sol[i],DESolution_getindex_adjoint
end

ZygoteRules.@adjoint function getindex(sol::DESolution, i, j...)
  function DESolution_getindex_adjoint(Δ)
    Δ′ = zero(sol)
    Δ′[i,j...] = Δ
    (Δ′, map(_ -> nothing, i)...)
  end
  sol[i,j...],DESolution_getindex_adjoint
end

ZygoteRules.@adjoint function (f::ODEFunction)(u,p,t)
  if f.vjp === nothing
    out = f.f(u,p,t)
    ZygoteRules.adjoint(f.f,u,p,t)
  else
    function ode_vjp(d)
      f.vjp(d,u,p,t)
    end
    return out,ode_vjp
  end
end

ZygoteRules.@adjoint! function (f::ODEFunction)(du,u,p,t)
  if f.vjp === nothing
    ZygoteRules.adjoint!(f.f,du,u,p,t)
  else
    f.f(du,u,p,t)
    function ode_vjp(d)
      f.vjp(du,d,u,p,t)
    end
    return nothing,ode_vjp
  end
end

#=
ChainRulesCore.frule(f::ODEFunction,u,p,t)
  if f.jvp === nothing
    ChainRulesCore.frule(f.f,u,p,t)
  else
    function ode_jvp(f,du,dp,dt)
      f.jvp_u(du,u,p,t) + f.jvp_p(dp,u,p,t) + f.tgrad(u,p,t)*dt
    end
    f.f(u,p,t),ode_jvp
end
=#

ChainRulesCore.rrule(f::ODEFunction,u,p,t)
  if f.vjp === nothing
    ChainRulesCore.rrule(f.f,u,p,t)
  else
    function ode_vjp(f,d)
      f.vjp(d,u,p,t)
    end
    f.f(u,p,t),ode_jvp
end
