const QUBIST_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

@doc raw"""
""" mutable struct Qubist{D<:SpinDomain} <: AbstractBQPModel{D}
    backend::QUBIST_BACKEND_TYPE{D}
    sites::Int
    lines::Int

    function Qubist{D}(
        backend::QUBIST_BACKEND_TYPE{D},
        sites::Integer,
        lines::Integer,
    ) where {D<:SpinDomain}
        new{D}(backend, sites, lines)
    end

    function Qubist{D}(
        linear_terms::Dict{Int,Float64},
        quadratic_terms::Dict{Tuple{Int,Int},Float64},
        sites::Integer,
        lines::Integer,
    ) where {D<:SpinDomain}
        variable_map = BQPIO._build_varmap(
            linear_terms,
            quadratic_terms
        )

        linear_terms, quadratic_terms = BQPIO._remap_terms(
            linear_terms,
            quadratic_terms,
            variable_map,
        )

        backend = QUBIST_BACKEND_TYPE{D}(
            linear_terms,
            quadratic_terms,
            variable_map;
        )
        
        Qubist{D}(backend, sites, lines)
    end

    function Qubist(args...)
        Qubist{SpinDomain}(args...)
    end
end

function BQPIO.isvalidbridge(
    source::Qubist{D},
    target::Qubist{D},
    ::Type{<:Qubist{D}};
    kws...
) where {D<:SpinDomain}
    flag = true

    if source.sites != target.sites
        @error "Test Failure: Inconsistent number of sites"
        flag = false
    end

    if source.lines != target.lines
        @error "Test Failure: Inconsistent number of lines"
        flag = false
    end

    if !BQPIO.isvalidbridge(
        BQPIO.backend(source),
        BQPIO.backend(target);
        kws...
    )
        flag = false
    end

    return flag
end