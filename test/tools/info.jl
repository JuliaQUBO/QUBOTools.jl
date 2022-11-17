const TEST_CASES = Dict{Type,UnitRange}(
    BQPJSON{𝔹}  => 0:2,
    BQPJSON{𝕊}  => 0:2,
    HFS{𝔹}      => 1:0,
    MiniZinc{𝔹} => 0:0,
    MiniZinc{𝕊} => 0:0,
    Qubist{𝕊}   => 0:2,
    QUBO{𝔹}     => 0:2,
)