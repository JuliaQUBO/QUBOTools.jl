QUBOTools.backend(model::StandardQUBOModel) = model

QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_OFFSET) = model.offset
QUBOTools._defaultattr(::StandardQUBOModel{<:Any,<:Any,T,<:Any}, ::ATTR_OFFSET) where {T} = zero(T)
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_SCALE) = model.scale
QUBOTools._defaultattr(::StandardQUBOModel{<:Any,<:Any,T,<:Any}, ::ATTR_SCALE) where {T} = one(T)
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_ID) = model.id
QUBOTools._defaultattr(::StandardQUBOModel, ::ATTR_ID) = 0
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_VERSION) = model.version
QUBOTools._defaultattr(::StandardQUBOModel, ::ATTR_VERSION) = v"1.0.0"
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_DESCRIPTION) = model.description
QUBOTools._defaultattr(::StandardQUBOModel, ::ATTR_DESCRIPTION) = ""
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_METADATA) = model.metadata
QUBOTools._defaultattr(::StandardQUBOModel, ::ATTR_METADATA) = Dict{String,Any}()
QUBOTools.getattr(model::StandardQUBOModel, ::ATTR_SAMPLESET) = model.sampleset
QUBOTools._defaultattr(::StandardQUBOModel{<:Any,U,T,<:Any}, ::ATTR_SAMPLESET) where {U,T} = SampleSet{U,T}()

QUBOTools.linear_terms(model::StandardQUBOModel) = model.linear_terms
QUBOTools.quadratic_terms(model::StandardQUBOModel) = model.quadratic_terms
QUBOTools.variable_map(model::StandardQUBOModel) = model.variable_map
QUBOTools.variable_map(model::StandardQUBOModel{V,<:Any,<:Any,<:Any}, v::V) where {V} = model.variable_map[v]
QUBOTools.variable_inv(model::StandardQUBOModel) = model.variable_inv
QUBOTools.variable_inv(model::StandardQUBOModel, i::Integer) = model.variable_inv[i]

function QUBOTools.energy(state::Vector{U}, model::StandardQUBOModel{<:Any,U,T,<:Any}) where {U,T}
    s = zero(T)

    for (i, l) in model.linear_terms
        s += state[i] * l
    end

    for ((i, j), q) in model.quadratic_terms
        s += state[i] * state[j] * q
    end

    return s
end