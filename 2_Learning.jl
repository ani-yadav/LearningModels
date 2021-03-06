################################################################################
############################## BELIEF FORMATION ################################
################################################################################

using StatsBase

function learning(α, β, β_k, yit, ρ, var_α,var_β,cov_αβ,var_η, var_ɛ, g_t,
  fpu, wrong = false)

  println("Calculate agent's beliefs")
  tW = size(yit,2); s_f_i = Array{Float64}(undef, 3, size(yit)...)

  if wrong
    β_k -= (β.>percentile(β, 80))*0.01
    β_k -= (β.<=percentile(β, 80)).*(β.>percentile(β, 60))*0.005
    β_k += (β.<=percentile(β, 40)).*(β.>percentile(β, 20))*0.005
    β_k += (β.<=percentile(β, 20))*0.001
  end

  # Initial belief is the known part of β
  for i = 1:length(β)
    s_f_i[:, i, 1] = [α[i]; β_k[i]; 0.0]
  end

  f = [1. 0. 0.; 0. 1. 0.; 0. 0. ρ]
  q = [0. 0. 0.; 0. 0. 0.; 0. 0. var_η]
  p_f = Array{Float64}(undef, 3, 3, tW)
  p_f[:,:,1] = [       var_α       sqrt(1-fpu)*cov_αβ       0.0;
                sqrt(1-fpu)*cov_αβ   (1-fpu)*var_β          0.0;
                        0.0                 0.0        var_η/(1-ρ^2.)]

  # Evolution of Var-Cov-Matrix
  stdy = Array{Float64}(undef, tW); k = Array{Float64}(undef, 3, tW)
  for t = 1:tW
    ht = [1; t; 1]
    pt = p_f[:, :, t]
    k[:, t] = pt*ht.*(ht'*pt*ht + var_ɛ).^(-1.0)
    stdy[t] = sqrt(ht'*p_f[:, :, t]*ht + var_ɛ)[1]
    if t < tW
      p_f[:, :, t+1] = f*(pt-pt*ht.*(ht'*pt*ht+var_ɛ).^(-1.0)*ht'*pt)*f' + q
      for i = 1:size(yit,1)
        s_f_i[:, i, t+1] = f*(s_f_i[:, i, t]
                            + k[:,t].*(log(yit[i, t]) - g_t[t] - ht'*s_f_i[:, i, t]))
      end
    end
  end

  return s_f_i, stdy, k, p_f
end
