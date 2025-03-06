function Format{:rudy}(; domain::Union{Symbol,Domain} = :spin)
    return Format{:rudy}(
        Dict{Symbol,Any}(
            :domain => QUBOTools.domain(domain)
        )
    )
end

infer_format(::Val{:rudy})               = Format{:rudy}()
infer_format(::Val{:bool}, ::Val{:rudy}) = Format{:rudy}(; domain = :bool)
infer_format(::Val{:spin}, ::Val{:rudy}) = Format{:rudy}(; domain = :spin)

@kwdef mutable struct RUDY_DATA{T}
    dimension::Int                            = 0
    scale::T                                  = 1.0
    offset::T                                 = 0.0
    sense::Sense                              = QUBOTools.sense(:min)
    domain::Domain                            = QUBOTools.domain(:bool)
    linear_terms::Dict{Int,T}                 = Dict{Int,T}()
    quadratic_terms::Dict{Tuple{Int,Int},T}   = Dict{Tuple{Int,Int},T}()
    metadata::Dict{String,Any}                = Dict{String,Any}()
end

function parse_comment!(data, line::AbstractString, ::Format{:rudy})
    # Generated 2024-11-28 21:58:00.190076
    # Note: last characters are trimmed!
    let m = match(r"^# Generated (\d{1,4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}\.\d{1,3})\d+$", line)
        if !isnothing(m)
            data.metadata["timestamp"] = Dates.DateTime(m[1], Dates.dateformat"yyyy-mm-dd HH:MM:SS.s")

            return nothing
        end
    end

    # Constant term of objective = 66363.47
    let m = match(r"^# Constant term of objective = ([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+))$", line)
        if !isnothing(m)
            data.offset = parse(Float64, m[1])

            return nothing
        end
    end

    return nothing
end

function parse_line!(data::RUDY_DATA{T}, line::AbstractString, fmt::Format{:rudy}) where {T}
    startswith(line, "#") && return parse_comment!(data, line, fmt)
    
    let m = match(r"^(\d+)\s+(\d+)\s+([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+))$", line)
        if !isnothing(m)
            # Note: rudy is 0-indexed!
            i = parse(Int, m[1]) + 1
            j = parse(Int, m[2]) + 1
            c = parse(T, m[3])

            data.dimension = max(data.dimension, i, j)

            if i == j
                data.linear_terms[i] = get(data.linear_terms, i, zero(T)) + c
            else
                data.quadratic_terms[(i, j)] = get(data.quadratic_terms, (i, j), zero(T)) + c
            end
        else
            QUBOTools.syntax_error("Invalid input: '$line'")
        end
    end
end

function QUBOTools.read_model(io::IO, fmt::QUBOTools.Format{:rudy})
    data = RUDY_DATA{Float64}(; domain = QUBOTools.domain(fmt[:domain]))

    for line in Iterators.map(strip, eachline(io))
        !isempty(line) && parse_line!(data, line, fmt)
    end
    
    return QUBOTools.Model{Int,Float64,Int}(
        Set{Int}(1:data.dimension),
        data.linear_terms,
        data.quadratic_terms;
        scale       = data.scale,
        offset      = data.offset,
        sense       = data.sense,
        domain      = data.domain,
        metadata    = data.metadata,
    )
end
