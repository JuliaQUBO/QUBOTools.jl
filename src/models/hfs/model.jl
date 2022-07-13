raw"""
Format description from [alex1770/QUBO-Chimera](https://github.com/alex1770/QUBO-Chimera)
The format of the instance-description file starts with a line giving the size of the Chimera graph.
(Two numbers are given to specify an m x n rectangle, but currently only a square, m=n, is accepted.)
The subsequent lines are of the form
```
    <Chimera vertex> <Chimera vertex> weight
```
where `<Chimera vertex>` is specified by four numbers using the format,
Chimera graph, C_N:
    Vertices are (x,y,o,i)  0<=x,y<N, 0<=o<2, 0<=i<4
    Edge from (x,y,o,i) to (x",y",o",i") if
    (x,y)=(x",y"), o!=o", OR
    |x-x"|=1, y=y", o=o"=0, i=i", OR
    |y-y"|=1, x=x", o=o"=1, i=i"
        
    x,y are the horizontal,vertical co-ords of the K4,4
    o=0..1 is the "orientation" (0=horizontally connected, 1=vertically connected)
    i=0..3 is the index within the "semi-K4,4"="bigvertex"
    There is an involution given by {x<->y o<->1-o}
"""

const HFS_DEFAULT_CHIMERA_CELL_SIZE = 8
const HFS_DEFAULT_PRECISION = 5

@doc raw"""
""" struct HFS{D <: BoolDomain} <: AbstractBQPModel{D}
    normal_factor::Float64
    normal_scale::Float64
    normal_offset::Float64

    variable_ids::Set{Int}
    linear_terms::Dict{Int, Float64}
    quadratic_terms::Dict{Tuple{Int, Int}, Float64}
    int_linear_terms::Dict{Int, Int}
    int_quadratic_terms::Dict{Tuple{Int, Int}, Int}

    # ~*~ Metadata ~*~ #
    precision::Int
    chimera_cell_size::Int
    chimera_degree::Int
    chimera_effective_degree::Int
    chimera_coordinate::Dict{Int, Tuple{Int, Int, Int, Int}}
    
    function HFS{D}(
        scale::Float64,
        offset::Float64,
        linear_terms::Dict{Int, Float64}
        quadratic_terms::Dict{Tuple{Int, Int}, Float64}
        chimera_cell_size::Union{Integer, Nothing} = nothing,
        chimera_degree::Union{Integer, Nothing} = nothing,
        precision::Union{Integer, Nothing} = nothing,
    ) where D <: BoolDomain
        variable_ids = Set{Int}()
        max_variable_id = maximum(variable_ids)

        if isnothing(chimera_cell_size)
            @warn "Assuming 'chimera_cell_size' = $(HFS_DEFAULT_CHIMERA_CELL_SIZE)"
            chimera_cell_size = HFS_DEFAULT_CHIMERA_CELL_SIZE
        end

        min_chimera_degree = ceil(Int, sqrt(max_variable_id / chimera_cell_size))

        if isnothing(chimera_degree)
            @warn "Assuming 'chimera_degree' = $(min_chimera_degree)"
            chimera_degree = min_chimera_degree
        end

        if chimera_degree < min_chimera_degree
            error(
            """
            Error: chimera_degree of $(chimera_degree) was specified.
            However, the minimum chimera_degree required for a problem with a variable index of '$(max_variable_id)' is '$(min_chimera_degree)'.
            """
            )
        end

        if isnothing(precision)
            @warn "Assuming 'precision' = $(HFS_DEFAULT_PRECISION)"
            precision = HFS_DEFAULT_PRECISION
        end

        chimera_cell_row_size = chimera_cell_size ÷ 2

        # These values are used to transform a variable index into a chimera 
        # coordinate (x,y,o,i)
        # x - chimera_row
        # y - chimera_column
        # o - chimera_cell_column - indicates the first or the second row of a chimera cell
        # i - chimera_cell_column_id - indicates ids within a chimera cell
        # Note that knowing the size of source chimera graph is essential to doing this mapping correctly 
    
        chimera_cell_column = Dict{Int, Int}(
            i => (i % chimera_cell_size) ÷ chimera_cell_row_size for i in variable_ids
        )
        chimera_cell_column_id = Dict{Int, Int}(
            i => (i % chimera_cell_row_size) for i in variable_ids
        )
        chimera_cell = Dict{Int, Int}(
            i => (i ÷ chimera_cell_size) for i in variable_ids
        )
        chimera_row = Dict{Int, Int}(
            i => (j ÷ chimera_degree) for (i, j) in chimera_cell
        )
        chimera_column = Dict{Int, Int}(
            i => (j % chimera_degree) for (i, j) in chimera_cell
        )
        chimera_coordinate = Dict{Int, Tuple{Int, Int, Int, Int}}(
            i => (
                chimera_row[i],
                chimera_column[i],
                chimera_cell_column[i],
                chimera_cell_column_id[i],
            )
            for i in variable_ids
        )
        chimera_effective_degree = 1 + max(maximum(values(chimera_row)), maximum(values(chimera_column)))
    
        if chimera_effective_degree > chimera_degree
            error()
        end

        max_abs_coeff = maximum(abs.([values(linear_terms);values(quadratic_terms)]))
        normal_factor = 10 ^ precision / max_abs_coeff

        int_linear_terms    = Dict{Int, Int}()
        int_quadratic_terms = Dict{Int, Int}()

        for (i, q) in linear_terms
            int_linear_terms[i] = round(Int, normal_factor * q)
        end

        for ((i, j), Q) in quadratic_terms
            int_quadratic_terms[(i, j)] = round(Int, normal_factor * Q)
        end

        normal_scale  = scale / normal_factor
        normal_offset = offset * normal_factor

        new{D}(
            normal_factor,
            normal_scale,
            normal_offset,
            variable_ids,
            linear_terms,
            quadratic_terms,
            int_linear_terms,
            int_quadratic_terms,
            precision,
            chimera_cell_size,
            chimera_degree,
            chimera_effective_degree,
            chimera_coordinate,
        )
    end
end