const CONSTRUCTOR_REPEATS = 8

function benchmark_constructors!(suite, fixtures)
    for fixture in fixtures
        fixture_group = suite[fixture.label] = BenchmarkGroup()

        fixture_group["Model"] = @benchmarkable repeat_last(
            () -> QUBOTools.Model(
                $(fixture.linear),
                $(fixture.quadratic);
                scale = 1.0,
                offset = -1.0,
                sense = :max,
                domain = :spin,
            ),
            $CONSTRUCTOR_REPEATS,
        )
        fixture_group["Model/MOI"] = @benchmarkable repeat_last(
            () -> QUBOTools.Model($(fixture.moi_model)),
            $CONSTRUCTOR_REPEATS,
        )
    end

    return suite
end
