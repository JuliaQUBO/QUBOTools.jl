const DATA_PATH = joinpath(@__DIR__, "..", "data")

const TEST_DATA_PATH = Dict{Type,Function}(
    BQPJSON{𝔹}  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.json"),
    BQPJSON{𝕊}  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.json"),
    HFS{𝔹}      => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.hfs"),
    MiniZinc{𝔹} => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.mzn"),
    MiniZinc{𝕊} => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.mzn"),
    Qubist{𝕊}   => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.qh"),
    QUBO{𝔹}     => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.qubo"),
)

const TEMP_DATA_PATH = Dict{Type,Function}(
    BQPJSON{𝔹}  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.temp.json"),
    BQPJSON{𝕊}  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.temp.json"),
    HFS{𝔹}      => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.temp.hfs"),
    MiniZinc{𝔹} => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.temp.mzn"),
    MiniZinc{𝕊} => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.temp.mzn"),
    Qubist{𝕊}   => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.temp.qh"),
    QUBO{𝔹}     => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.temp.qubo"),
)
