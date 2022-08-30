Base.convert(
    ::Type{<:StandardQUBOModel{V,U,T,D}},
    model::StandardQUBOModel{V,U,T,D}
) where {V,U,T,D} = model # Short-circuit! Yeah!

function Base.convert(
    ::Type{<:StandardQUBOModel{V,U,T,B}},
    model::StandardQUBOModel{V,U,T,A}
) where {V,U,T,A,B}
    _linear_terms, _quadratic_terms, offset = QUBOTools._swapdomain(
        A,
        B,
        model.linear_terms,
        model.quadratic_terms,
        model.offset,
    )

    linear_terms, quadratic_terms, _ = QUBOTools._normal_form(
        _linear_terms,
        _quadratic_terms,
    )

    StandardQUBOModel{V,U,T,B}(
        linear_terms,
        quadratic_terms,
        copy(model.variable_map),
        copy(model.variable_inv);
        scale=model.scale,
        offset=offset,
        id=model.id,
        version=model.version,
        description=model.description,
        metadata=deepcopy(model.metadata),
        sampleset=model.sampleset
    )
end

function Base.copy!(
    target::StandardQUBOModel{V,U,T,D},
    source::StandardQUBOModel{V,U,T,D},
) where {V,U,T,D}
    target.linear_terms = copy(source.linear_terms)
    target.quadratic_terms = copy(source.quadratic_terms)
    target.variable_map = copy(source.variable_map)
    target.variable_inv = copy(source.variable_inv)
    target.scale = source.scale
    target.offset = source.offset
    target.id = source.id
    target.version = source.version
    target.description = source.description
    target.metadata = deepcopy(source.metadata)
    target.sampleset = source.sampleset

    return target
end

function Base.copy!(
    target::StandardQUBOModel{V,U,T,B},
    source::StandardQUBOModel{V,U,T,A},
) where {V,U,T,A,B}
    return copy!(target, convert(StandardQUBOModel{V,U,T,B}, source))
end