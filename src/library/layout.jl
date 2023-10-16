function topology(g::AbstractGraph)
    return g
end

function geometry(g::AbstractGraph)
    return NetworkLayout.layout(NetworkLayout.Shell(; Ptype = Float64), g)
end

function topology(A::AbstractMatrix{T}) where {T}
    return Graphs.Graph(A)
end

function geometry(x::Any)
    return geometry(topology(x))
end

function layout(x::Any)
    g = QUBOTools.topology(x)
    P = QUBOTools.geometry(g)

    return Layout(g, P)
end
