raw"""
    Format{:qubo}(; style::Union{Symbol,Nothing})

The `style` could be `:dwave`, `:qbsolv`, `:mqlib` or `nothing`.
"""
function Format{:qubo}(; style::Union{Symbol,Nothing} = nothing)
    if isnothing(style)
        return Format{:qubo}(Dict{Symbol,Any}())
    elseif style === :dwave || style === :qbsolv
        return Format{:qubo}(Dict{Symbol,Any}(:style => :dwave))
    elseif style === :mqlib
        return Format{:qubo}(Dict{Symbol,Any}(:style => :mqlib))
    else
        error(
            "Unkown style '$style' for QUBO files. Options are: ':dwave', ':qbsolv' and ':mqlib'",
        )
    end
end

infer_format(::Val{:dwave})  = Format{:qubo}(; style = :dwave)
infer_format(::Val{:mqlib})  = Format{:qubo}(; style = :mqlib)
infer_format(::Val{:qbsolv}) = Format{:qubo}(; style = :qbsolv)
infer_format(::Val{:qubo})   = Format{:qubo}(; style = :dwave) # defaults to dwave style

include("parser.jl")
include("printer.jl")
