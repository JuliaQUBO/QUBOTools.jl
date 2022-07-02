function test_samples()
    @testset "Samples" begin
        setx = BQPIO.SampleSet{UInt8, Float64}(
            BQPIO.Sample{UInt8, Float64}[
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 1], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 1, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 1, 0, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[1, 0, 0, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 0], 1, 0.0),
            ])

        sety = BQPIO.SampleSet{UInt8, Float64}(
            BQPIO.Sample{UInt8, Float64}[
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 0], 2, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 1], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 1, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 1, 0, 0], 1, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[1, 0, 0, 0], 1, 0.0),
            ])

        setz = BQPIO.SampleSet{UInt8, Float64}(
            BQPIO.Sample{UInt8, Float64}[
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 0], 4, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 0, 1], 2, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 0, 1, 0], 2, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[0, 1, 0, 0], 2, 0.0),
                BQPIO.Sample{UInt8, Float64}(UInt8[1, 0, 0, 0], 2, 0.0),
            ])

        @test setx == sety
        @test merge(setx, sety) == setz
    end
end