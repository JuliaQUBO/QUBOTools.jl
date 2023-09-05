# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

@doc raw"""
    Chimera(cell_size::Integer, precision::Integer)
    
The format of the instance-description file starts with a line giving the size of the Chimera graph[^chimera].
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

[^chimera]: alex1770's QUBO-Chimera Git Repository [{git}](https://github.com/alex1770/QUBO-Chimera)
"""
struct Chimera <: DWaveArchitecture
    cell_size::Int
    precision::Int

    function Chimera(
        cell_size::Integer = 8,
        precision::Integer = 5,
    )
        return new(cell_size, precision)
    end
end

function layout(arch::Chimera)
    # TODO: Retrieve this information from dwave-networkx

    return nothing
end