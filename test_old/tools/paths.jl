const DATA_PATH = joinpath(@__DIR__, "..", "data")

const TEST_DATA_PATH = Dict{Tuple{Type,QUBOTools.Domain},Function}(
    (BQPJSON, 𝔹)  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.json"),
    (BQPJSON, 𝕊)  => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.json"),
    (HFS, 𝔹)      => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.hfs"),
    (MiniZinc, 𝔹) => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.mzn"),
    (MiniZinc, 𝕊) => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.mzn"),
    (Qubist, 𝕊)   => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "spin.qh"),
    (QUBO, 𝔹)     => (i::Integer) -> joinpath(DATA_PATH, @sprintf("%02d", i), "bool.qubo"),
)

const TEMP_DATA_PATH = Dict{Tuple{Type,QUBOTools.Domain},Function}(
    (BQPJSON, 𝔹)  => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.bool.temp.json", i)),
    (BQPJSON, 𝕊)  => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.spin.temp.json", i)),
    (HFS, 𝔹)      => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.bool.temp.hfs", i)),
    (MiniZinc, 𝔹) => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.bool.temp.mzn", i)),
    (MiniZinc, 𝕊) => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.spin.temp.mzn", i)),
    (Qubist, 𝕊)   => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.spin.temp.qh", i)),
    (QUBO, 𝔹)     => (i::Integer) -> joinpath(tempdir(), @sprintf("%02d.bool.temp.qubo", i)),
)
