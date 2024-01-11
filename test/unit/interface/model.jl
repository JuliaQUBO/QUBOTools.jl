struct ModelWrapper
    model::QUBOTools.Model{Symbol,Float64,Int}

    ModelWrapper(model::QUBOTools.Model{Symbol,Float64,Int}) = new(model)
end

QUBOTools.backend(model::ModelWrapper) = model.model

function test_model_interface()
    @testset "→ ModelWrapper" begin
        model = ModelWrapper(
            QUBOTools.Model{Symbol,Float64,Int}(
                Dict{Symbol,Float64}(:x => 1.0, :y => 2.0, :z => 3.0, :w => 4.0),
                Dict{Tuple{Symbol,Symbol},Float64}(
                    (:x, :y) => 12.0,
                    (:x, :z) => 13.0,
                    (:x, :w) => 14.0,
                    (:y, :z) => 23.0,
                    (:y, :w) => 24.0,
                    (:z, :w) => 34.0,
                );
                scale       = 2.0,
                offset      = 1.0,
                sense       = :min,
                domain      = :spin,
                id          = 10,
                description = "Wrapped Model",
                metadata    = Dict{String,Any}("author" => "Wilhelm Lenz", "year" => "1920"),
                start       = Dict{Symbol,Int}(:x => 1, :y => -1, :w => -1),
                solution    = SampleSet([Sample([↓, ↓, ↑, ↑], -90.0, 3), Sample([↑, ↑, ↓, ↓], -90.0, 1), Sample([↓, ↑, ↑, ↑], -50.0, 4), Sample([↑, ↓, ↓, ↓], -42.0, 2), Sample([↓, ↓, ↓, ↑], -30.0, 2), Sample([↑, ↑, ↓, ↑], -6.0, 1), Sample([↓, ↓, ↓, ↓], 262.0, 5)]; sense = :min, domain = :spin),
            ),
        )

        @testset "Data access" begin
            @test Dict(QUBOTools.linear_terms(model)) == Dict( #
                1 => 4.0,
                2 => 1.0,
                3 => 2.0,
                4 => 3.0,
            )
            @test Dict(QUBOTools.quadratic_terms(model)) == Dict( #
                (2, 4) => 13.0,
                (1, 2) => 14.0,
                (1, 3) => 24.0,
                (3, 4) => 23.0,
                (1, 4) => 34.0,
                (2, 3) => 12.0,
            )
            @test QUBOTools.scale(model) == 2.0
            @test QUBOTools.offset(model) == 1.0
            @test QUBOTools.sense(model) == QUBOTools.sense(:min)
            @test QUBOTools.domain(model) == QUBOTools.domain(:spin)
            @test QUBOTools.id(model) == 10
            @test QUBOTools.description(model) == "Wrapped Model"
            @test QUBOTools.metadata(model) == Dict{String,Any}(
                "author"      => "Wilhelm Lenz",
                "year"        => "1920",
                "id"          => 10,
                "description" => "Wrapped Model",
            )
        end

        @testset "Variables" begin
            @test_throws Exception QUBOTools.index(model, :u)
            @test_throws Exception QUBOTools.index(model, :v)
            @test QUBOTools.index(model, :w) == 1
            @test QUBOTools.index(model, :x) == 2
            @test QUBOTools.index(model, :y) == 3
            @test QUBOTools.index(model, :z) == 4

            @test QUBOTools.hasindex(model, 0) == false
            @test QUBOTools.hasindex(model, 1) == true
            @test QUBOTools.hasindex(model, 2) == true
            @test QUBOTools.hasindex(model, 3) == true
            @test QUBOTools.hasindex(model, 4) == true
            @test QUBOTools.hasindex(model, 5) == false

            @test QUBOTools.indices(model) == [1, 2, 3, 4]

            @test_throws Exception QUBOTools.variable(model, 0)
            @test QUBOTools.variable(model, 1) == :w
            @test QUBOTools.variable(model, 2) == :x
            @test QUBOTools.variable(model, 3) == :y
            @test QUBOTools.variable(model, 4) == :z
            @test_throws Exception QUBOTools.variable(model, 5)

            @test QUBOTools.hasvariable(model, :u) == false
            @test QUBOTools.hasvariable(model, :v) == false
            @test QUBOTools.hasvariable(model, :w) == true
            @test QUBOTools.hasvariable(model, :x) == true
            @test QUBOTools.hasvariable(model, :y) == true
            @test QUBOTools.hasvariable(model, :z) == true

            @test QUBOTools.variables(model) == [:w, :x, :y, :z]
        end

        @testset "Model's Normal Forms" begin
            # Model's Normal Forms
            # form(src, args...; kws...)  = form(backend(src), args...; kws...)
            # qubo(src, args...; kws...)  = qubo(backend(src), args...; kws...)
            # ising(src, args...; kws...) = ising(backend(src), args...; kws...)                       
        end

        @testset "Solution" begin
            @test QUBOTools.state(model, 1) == [↓, ↓, ↑, ↑]
            @test QUBOTools.state(model, 2) == [↑, ↑, ↓, ↓]
            @test QUBOTools.state(model, 3) == [↓, ↑, ↑, ↑]
            @test QUBOTools.state(model, 4) == [↑, ↓, ↓, ↓]
            @test QUBOTools.state(model, 5) == [↓, ↓, ↓, ↑]
            @test QUBOTools.state(model, 6) == [↑, ↑, ↓, ↑]
            @test QUBOTools.state(model, 7) == [↓, ↓, ↓, ↓]

            @test QUBOTools.value(model, 1) == -90.0
            @test QUBOTools.value(model, 2) == -90.0
            @test QUBOTools.value(model, 3) == -50.0
            @test QUBOTools.value(model, 4) == -42.0
            @test QUBOTools.value(model, 5) == -30.0
            @test QUBOTools.value(model, 6) == -6.0
            @test QUBOTools.value(model, 7) == 262.0

            @test QUBOTools.reads(model) == 18
            @test QUBOTools.reads(model, 1) == 3
            @test QUBOTools.reads(model, 2) == 1
            @test QUBOTools.reads(model, 3) == 4
            @test QUBOTools.reads(model, 4) == 2
            @test QUBOTools.reads(model, 5) == 2
            @test QUBOTools.reads(model, 6) == 1
            @test QUBOTools.reads(model, 7) == 5

            @test QUBOTools.hassample(model, 0) == false
            @test QUBOTools.hassample(model, 1) == true
            @test QUBOTools.hassample(model, 2) == true
            @test QUBOTools.hassample(model, 3) == true
            @test QUBOTools.hassample(model, 4) == true
            @test QUBOTools.hassample(model, 5) == true
            @test QUBOTools.hassample(model, 6) == true
            @test QUBOTools.hassample(model, 7) == true
            @test QUBOTools.hassample(model, 8) == false

            @test_throws Exception QUBOTools.sample(model, 0)
            @test QUBOTools.sample(model, 1) == Sample([↓, ↓, ↑, ↑], -90.0, 3)
            @test QUBOTools.sample(model, 2) == Sample([↑, ↑, ↓, ↓], -90.0, 1)
            @test QUBOTools.sample(model, 3) == Sample([↓, ↑, ↑, ↑], -50.0, 4)
            @test QUBOTools.sample(model, 4) == Sample([↑, ↓, ↓, ↓], -42.0, 2)
            @test QUBOTools.sample(model, 5) == Sample([↓, ↓, ↓, ↑], -30.0, 2)
            @test QUBOTools.sample(model, 6) == Sample([↑, ↑, ↓, ↑], -6.0, 1)
            @test QUBOTools.sample(model, 7) == Sample([↓, ↓, ↓, ↓], 262.0, 5)
            @test_throws Exception QUBOTools.sample(model, 8)

            @test QUBOTools.solution(model) isa SampleSet
            @test length(QUBOTools.solution(model)) == 7

            @test_throws Exception QUBOTools.start(model, 0)
            @test QUBOTools.start(model, 1) == -1
            @test QUBOTools.start(model, 2) == 1
            @test QUBOTools.start(model, 3) == -1
            @test QUBOTools.start(model, 4) === nothing
            @test_throws Exception QUBOTools.start(model, 5)
        end

        @testset "Attachments" begin
            # Solution
            QUBOTools.attach!(
                model,
                SampleSet(
                    [
                        Sample([0, 0, 1, 1], 90.0, 3),
                        Sample([0, 1, 1, 1], 50.0, 4),
                        Sample([0, 0, 0, 1], 30.0, 2),
                        Sample([0, 0, 0, 0], -262.0, 5),
                    ];
                    sense  = :max,
                    domain = :bool,
                ),
            )

            @test QUBOTools.hassample(model, 0) == false
            @test QUBOTools.hassample(model, 1) == true
            @test QUBOTools.hassample(model, 2) == true
            @test QUBOTools.hassample(model, 3) == true
            @test QUBOTools.hassample(model, 4) == true
            @test QUBOTools.hassample(model, 5) == false

            @test QUBOTools.state(model, 1) == [↓, ↓, ↑, ↑]
            @test QUBOTools.state(model, 2) == [↓, ↑, ↑, ↑]
            @test QUBOTools.state(model, 3) == [↓, ↓, ↓, ↑]
            @test QUBOTools.state(model, 4) == [↓, ↓, ↓, ↓]

            @test QUBOTools.value(model, 1) == -90.0
            @test QUBOTools.value(model, 2) == -50.0
            @test QUBOTools.value(model, 3) == -30.0
            @test QUBOTools.value(model, 4) == 262.0

            @test QUBOTools.reads(model) == 14
            @test QUBOTools.reads(model, 1) == 3
            @test QUBOTools.reads(model, 2) == 4
            @test QUBOTools.reads(model, 3) == 2
            @test QUBOTools.reads(model, 4) == 5

            # Warm-start
            QUBOTools.attach!(model, Dict{Symbol,Int}(:w => 1, :x => -1, :y => 1, :z => -1))

            @test_throws Exception QUBOTools.start(model, 0)
            @test QUBOTools.start(model, 1) == 1
            @test QUBOTools.start(model, 2) == -1
            @test QUBOTools.start(model, 3) == 1
            @test QUBOTools.start(model, 4) === -1
            @test_throws Exception QUBOTools.start(model, 5)

            QUBOTools.attach!(model, :w => -1)
            QUBOTools.attach!(model, :x => 1)
            QUBOTools.attach!(model, :y => -1)
            QUBOTools.attach!(model, :z => 1)

            @test QUBOTools.start(model, 1) == -1
            @test QUBOTools.start(model, 2) == 1
            @test QUBOTools.start(model, 3) == -1
            @test QUBOTools.start(model, 4) === 1
        end

        @testset "Queries" begin
            @test QUBOTools.dimension(model) == 4
            @test QUBOTools.linear_size(model) == 4
            @test QUBOTools.quadratic_size(model) == 6
            @test QUBOTools.topology(model) == Graphs.SimpleGraphFromIterator(
                Graphs.Edge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]),
            )
        end
    end

    return nothing
end
