function Base.read(io::IO, ::Type{<:BQPJSON})
    @show data = JSON.parse(io)
end

function Base.write(io::IO, m::BQPJSON)
    data = Dict{String, Any}()

    JSON.print(io, data)
end

function Base.convert(M::Type{<:MiniZinc}, m::BQPJSON)
    @info "@ bqpjson"
end

function Base.convert(M::Type{<:QUBO}, m::BQPJSON)
    @info "@ bqpjson"
end

function Base.convert(M::Type{<:Qubist}, m::BQPJSON)
    @info "@ bqpjson"
end