const TEST_CASES = Dict{Type,UnitRange}(
    BQPJSON{𝔹}  => 0:3,
    BQPJSON{𝕊}  => 0:3,
    HFS{𝔹}      => 1:0,
    MiniZinc{𝔹} => 0:1,
    MiniZinc{𝕊} => 0:1,
    Qubist{𝕊}   => 0:3,
    QUBO{𝔹}     => 0:2,
)