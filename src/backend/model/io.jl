function Base.convert(::Type{<:StandardBQPModel{S,U,T,D}}, model::StandardBQPModel{S,U,T,D}) where {S,U,T,D}
    model # Short-circuit! Yeah!
end

function Base.convert(::Type{<:StandardBQPModel{S,U,T,B}}, model::StandardBQPModel{S,U,T,A}) where {S,U,T,A,B}
    linear_terms, quadratic_terms, offset = swapdomain(
        A,
        B,
        model.linear_terms,
        model.quadratic_terms,
        model.offset,
    )

    StandardBQPModel{S,U,T,B}(
        linear_terms,
        quadratic_terms,
        copy(model.variable_map),
        copy(model.variable_inv);
        offset=offset,
        scale=model.scale,
        id=model.id,
        version=model.version,
        description=model.description,
        metadata=deepcopy(model.metadata),
        sampleset=model.sampleset
    )
end

# function Base.read end
# function Base.write end