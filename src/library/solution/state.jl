function cast((s,t)::Route{D}, x::U) where {D<:Domain,U<:Integer}
    if s === t
        return x
    elseif s === 𝔹 && t === 𝕊
        return (2 * x) - 1
    elseif s === 𝕊 && t === 𝔹
        return (x + 1) ÷ 2
    else
        casting_error(s => t, x)
    end
end

function cast((s,t)::Route{D}, ψ::S) where {D<:Domain,U,S<:State{U}}
    if s === t
        return ψ
    elseif s === 𝔹 && t === 𝕊
        return (2 .* ψ) .- 1
    elseif s === 𝕊 && t === 𝔹
        return (ψ .+ 1) .÷ 2
    else
        casting_error(s => t, ψ)
    end
end
