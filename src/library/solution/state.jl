const State{U<:Integer} = AbstractVector{U}

function cast((s,t)::Pair{D,D}, x::U) where {D<:Domain,U<:Integer}
    if s === t
        return x
    elseif s === 𝔹 && t === 𝕊
        return (2 * x) - 1
    elseif s === 𝕊 && t === 𝔹
        return (x + 1) ÷ 2
    else
        error("Unknown domain cast route '$(s) => $(t)'")
    end
end

function cast((s,t)::Pair{D,D}, ψ::S) where {D<:Domain,U,S<:State{U}}
    if s === t
        return ψ
    elseif s === 𝔹 && t === 𝕊
        return (2 .* ψ) .- 1
    elseif s === 𝕊 && t === 𝔹
        return (ψ .+ 1) .÷ 2
    else
        error("Unknown domain cast route '$(s) => $(t)'")
    end
end
