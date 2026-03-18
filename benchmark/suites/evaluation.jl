const VALUE_REPEATS = 64

function benchmark_evaluation!(suite, fixtures)
    for fixture in fixtures
        fixture_group = suite[fixture.label] = BenchmarkGroup()

        fixture_group["value/model"] = @benchmarkable repeat_sum(
            () -> QUBOTools.value($(fixture.model), $(fixture.psi)),
            $VALUE_REPEATS,
        )
        fixture_group["value/dense-form"] = @benchmarkable repeat_sum(
            () -> QUBOTools.value($(fixture.psi), $(fixture.dense_form)),
            $VALUE_REPEATS,
        )
        fixture_group["value/sparse-form"] = @benchmarkable repeat_sum(
            () -> QUBOTools.value($(fixture.psi), $(fixture.sparse_form)),
            $VALUE_REPEATS,
        )
        fixture_group["value/dict-form"] = @benchmarkable repeat_sum(
            () -> QUBOTools.value($(fixture.psi), $(fixture.dict_form)),
            $VALUE_REPEATS,
        )
    end

    return suite
end
