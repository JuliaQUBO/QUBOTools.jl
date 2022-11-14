# ~*~ Internal: bridge validation ~*~ #
@doc raw"""
    _isvalidbridge(source::M, target::M, ::Type{<:AbstractQUBOModel}; kws...) where M <: AbstractQUBOModel

Checks if the `source` model is equivalent to the `target` reference modulo the given origin type.
Key-word arguments `kws...` are passed to interal `isapprox(::T, ::T; kws...)` calls.

""" function _isvalidbridge end

function _isvalidbridge(
    source::QUBOTools.Qubist{QUBOTools.SpinDomain},
    target::QUBOTools.Qubist{QUBOTools.SpinDomain},
    ::Type{QUBOTools.BQPJSON{QUBOTools.SpinDomain}};
    kws...,
)
    return _isvalidbridge(QUBOTools.backend(source), QUBOTools.backend(target); kws...)
end

function _isvalidbridge(
    source::QUBOTools.BQPJSON{QUBOTools.SpinDomain},
    target::QUBOTools.BQPJSON{QUBOTools.SpinDomain},
    ::Type{QUBOTools.Qubist};
    kws...
)
    return _isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
end

function _isvalidbridge(
    source::BQPJSON{BoolDomain},
    target::BQPJSON{BoolDomain},
    ::Type{<:QUBO{BoolDomain}};
    kws...
)
    return _isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
end

function _isvalidbridge(
    source::QUBO{BoolDomain},
    target::QUBO{BoolDomain},
    ::Type{<:BQPJSON{BoolDomain}};
    kws...
)
    return _isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
end

_isvalidbridge(
    source::M,
    target::M,
    ::Type{<:QUBOTools.AbstractQUBOModel};
    kws...
) where {M<:QUBOTools.AbstractQUBOModel} = true

function _isvalidbridge(
    source::BQPJSON{B},
    target::BQPJSON{B},
    ::Type{<:BQPJSON{A}};
    kws...
) where {A,B}
    flag = true

    if QUBOTools.id(source) != QUBOTools.id(target)
        @error "Test Failure: ID mismatch"
        flag = false
    end

    if QUBOTools.version(source) != QUBOTools.version(target)
        @error "Test Failure: Version mismatch"
        flag = false
    end

    if QUBOTools.description(source) != QUBOTools.description(target)
        @error "Test Failure: Description mismatch"
        flag = false
    end

    if QUBOTools.metadata(source) != QUBOTools.metadata(target)
        @error "Test Failure: Inconsistent metadata"
        flag = false
    end

    # TODO: How to compare them?
    # if source.solutions != target.solutions
    #     @error "Test Failure: Inconsistent solutions"
    #     flag = false
    # end

    if !_isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
        flag = false
    end

    return flag
end

function _isvalidbridge(
    source::MiniZinc{D},
    target::MiniZinc{D},
    ::Type{<:MiniZinc{D}};
    kws...
) where {D<:QUBOTools.VariableDomain}
    return _isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
end

function _isvalidbridge(
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

    if !_isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
        flag = false
    end

    return flag
end

function _isvalidbridge(
    source::QUBO{D},
    target::QUBO{D},
    ::Type{<:QUBO{D}};
    kws...
) where {D<:BoolDomain}
    flag = true

    if source.max_index != target.max_index
        @error "Test Failure: Inconsistent maximum index"
        flag = false
    end

    if source.num_diagonals != target.num_diagonals
        @error "Test Failure: Inconsistent number of diagonals"
        flag = false
    end

    if source.num_elements != target.num_elements
        @error "Test Failure: Inconsistent number of elements"
        flag = false
    end

    if !_isvalidbridge(
        QUBOTools.backend(source),
        QUBOTools.backend(target);
        kws...
    )
        flag = false
    end

    return flag
end


function _isvalidbridge(
    source::QUBOTools.StandardQUBOModel{D,V,T,U},
    target::QUBOTools.StandardQUBOModel{D,V,T,U};
    kws...
) where {D,V,T,U}
    flag = true

    if !isnothing(source.id) && !isnothing(target.id) && (source.id != target.id)
        @error """
        Test Failure: ID mismatch:
        $(source.id) ≂̸ $(target.id)
        """
        flag = false
    end

    if !isnothing(source.description) && !isnothing(target.description) && (source.description != target.description)
        @error """
        Test Failure: Description mismatch:
        $(source.description) ≂̸ $(target.description)
        """
        flag = false
    end

    if !isnothing(source.metadata) && !isnothing(target.metadata) && (source.metadata != target.metadata)
        @error "Test Failure: Metadata mismatch"
        flag = false
    end

    if !QUBOTools._isapproxdict(source.linear_terms, target.linear_terms; kws...)
        @error """
        Test Failure: Linear terms mismatch:
        $(source.linear_terms) ≉ $(target.linear_terms)
        """
        flag = false
    end

    if !QUBOTools._isapproxdict(source.quadratic_terms, target.quadratic_terms; kws...)
        @error """
        Test Failure: Quadratic terms mismatch:
        $(source.quadratic_terms) ≉ $(target.quadratic_terms)
        """
        flag = false
    end

    if !isnothing(source.offset) && !isnothing(target.offset) && !isapprox(source.offset, target.offset; kws...)
        @error """
        Test Failure: Offset mismatch:
        $(source.offset) ≂̸ $(target.offset)
        """
        flag = false
    end

    if !isnothing(source.scale) && !isnothing(target.scale) && !isapprox(source.scale, target.scale; kws...)
        @error """
        Test Failure: Scale mismatch:
        $(source.scale) ≠ $(target.scale)
        """
        flag = false
    end

    return flag
end