const CONVERSION_REPEATS = 8

function benchmark_conversions!(suite, fixtures)
    for fixture in fixtures
        fixture_group = suite[fixture.label] = BenchmarkGroup()

        fixture_group["form/Matrix"] = @benchmarkable repeat_last(
            () -> QUBOTools.form($(fixture.model), Matrix),
            $CONVERSION_REPEATS,
        )
        fixture_group["form/SparseMatrixCSC"] = @benchmarkable repeat_last(
            () -> QUBOTools.form($(fixture.model), SparseMatrixCSC),
            $CONVERSION_REPEATS,
        )
        fixture_group["form/Dict"] = @benchmarkable repeat_last(
            () -> QUBOTools.form($(fixture.model), Dict),
            $CONVERSION_REPEATS,
        )
        fixture_group["form/Matrix/Float32"] = @benchmarkable repeat_last(
            () -> QUBOTools.form($(fixture.model), Matrix, Float32),
            $CONVERSION_REPEATS,
        )
        fixture_group["ising/Matrix"] = @benchmarkable repeat_last(
            () -> QUBOTools.ising($(fixture.model), Matrix),
            $CONVERSION_REPEATS,
        )
        fixture_group["qubo/Matrix"] = @benchmarkable repeat_last(
            () -> QUBOTools.qubo($(fixture.model), Matrix),
            $CONVERSION_REPEATS,
        )
        fixture_group["qubo/Matrix/min"] = @benchmarkable repeat_last(
            () -> QUBOTools.qubo($(fixture.model), Matrix; sense = :min),
            $CONVERSION_REPEATS,
        )
    end

    return suite
end
