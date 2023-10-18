# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

@doc raw"""
    Chimera
    
The format of the instance-description file starts with a line giving the size of the Chimera graph[^alex1770].
Two numbers are given to specify an ``m \times n`` rectangle, but currently only a square (``m = n``) is accepted.

The subsequent lines are of the form
```
    <Chimera vertex> <Chimera vertex> <weight>
```
where `<Chimera vertex>` is specified by four numbers using the format, Chimera graph, ``C_N``:
    
Vertices are ``v = (x, y, o, i)`` where
- ``x, y \in [0, N - 1]`` are the horizontal, vertical coordinates of the ``K_{4, 4}``
- ``o \in [0, 1]`` is the **orientation**: (``0 = \text{horizontally connected}``, ``1 = \text{vertically connected}``)
- ``i \in [0, 3]`` is the index within the "semi-``K_{4,4}``" or "bigvertex"
- There is an involution given by ``x \iff y``, ``o \iff 1 - o``

There is an edge from ``v_p`` to ``v_q`` if at least one of the following holds:
- ``(x_p, y_p) = (x_q, y_q) \wedge o_p \neq o_q``
- ``|x_p - x_q| = 1 \wedge y_p = y_q \wedge o_p = o_q = 0 \wedge i_p = i_q``
- ``x_p = x_q \wedge |y_p-y_q| = 1 \wedge o_p = o_q = 1 \wedge i_p = i_q``

[^alex1770]:
    `alex1770`'s QUBO-Chimera Git Repository [{git}](https://github.com/alex1770/QUBO-Chimera)

[^dwave]:
    **D-Wave QPU Architecture: Topologies** [{docs}](https://docs.dwavesys.com/docs/latest/c_gs_4.html)
"""
struct Chimera <: DWaveArchitecture
    grid_size::NTuple{2,Int}
    cell_size::Int
    precision::Int
    coordinates::Dict{Int,NTuple{4,Int}}
    degree::Int
    effective_degree::Int
end

function Chimera(
    m::Integer = 2_048, # 2000Q
    n::Integer = m;
    cell_size::Integer = 8,
    precision::Integer = 5,
    degree::Union{Integer,Nothing} = nothing, 
)
    @assert m > 0
    @assert n > 0
    @assert m == n # TODO: relax

    grid_size = (m, n)
    dimension = m * n

    min_degree = ceil(Int, sqrt(dimension / cell_size))

    if isnothing(degree)
        degree = min_degree
    end

    if degree < min_degree
        error(
            """
            Error: degree of '$(degree)' was specified.
            However, the minimum degree required for a system with '$(dimension)' sites is '$(min_degree)'.
            """,
        )
    end

    cell_row_size = cell_size ÷ 2

    # These values are used to transform a variable index into a chimera 
    # coordinate (x,y,o,i)
    # x - row
    # y - col
    # o - cell_col - indicates the first or the second row of a chimera cell
    # i - cell_col_id - indicates ids within a chimera cell
    # Note that knowing the size of source chimera graph is essential to doing this mapping correctly

    cell        = Dict{Int,Int}(i => (i ÷ cell_size) for i in 1:dimension)
    row         = Dict{Int,Int}(i => (j ÷ degree) for (i, j) in cell)
    col         = Dict{Int,Int}(i => (j % degree) for (i, j) in cell)
    cell_col    = Dict{Int,Int}(i => (i % cell_size) ÷ cell_row_size for i in 1:dimension)
    cell_col_id = Dict{Int,Int}(i => (i % cell_row_size) for i in 1:dimension)
    
    coordinates = Dict{Int,NTuple{4,Int}}(
        i => (row[i], col[i], cell_col[i], cell_col_id[i])
        for i in 1:dimension
    )

    # Get the maximum of both row id and column id (namely 'c[1]', 'c[2]')
    effective_degree = 1 + maximum((_, c) -> max(c[1], c[2]), coordinates)

    if effective_degree > degree
        error(
            """
            The effective degree '$effective_degree' value is greater than the chimera degree '$(degree)', which is infeasible.
            """,
        )
    end

    return Chimera(
        grid_size,
        cell_size,
        precision,
        coordinates,
        degree,
        effective_degree,
    )
end

function DWaveDevice(arch::Chimera, model::QUBOTools.AbstractModel{V}) where {V}
    L = collect(QUBOTools.linear_terms(model))
    Q = collect(QUBOTools.quadratic_terms(model))
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    γ = max( # maximum absolute value for a coefficient in 'model'
        maximum((_, v) -> abs(v), L),
        maximum((_, v) -> abs(v), Q),
    )

    γχ =  10 ^ arch.precision / γ

    # Chimera Coefficients
    Lχ = sizehint!(Dict{V,Int}(), length(L))
    Qχ = sizehint!(Dict{Tuple{V,V},Int}(), length(Q))

    for (i, v) in L
        xi = QUBOTools.variable(model, i) 

        Lχ[xi] = round(Int, v * αχ)
    end

    for ((i, j), v) in Q
        xi = QUBOTools.variable(model, i)
        xj = QUBOTools.variable(model, j)

        Qχ[(xi, xj)] = round(Int, v * αχ)
    end

    αχ = 1
    βχ = round(Int, β * γχ)

    factor = α * γχ

    return DWaveDevice(
        arch,
        QUBOTools.Model{V,Int,Int}(
            Set{V}(QUBOTools.variables(model)),
            Lχ,
            Qχ;
            scale    = αχ,
            offset   = βχ,
            sense    = QUBOTools.sense(model),
            domain   = QUBOTools.domain(model),
            metadata = copy(QUBOTools.metadata(model)),
            start    = QUBOTools.start(model),
        ),
        factor,
    )
end

function layout(arch::Chimera)
    # TODO: Retrieve this information from dwave-networkx?

    return nothing
end