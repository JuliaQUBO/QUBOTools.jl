function test_model()
    # ~*~ Types ~*~ #
    V = Symbol
    U = Int
    T = Float64

    # ~*~ Data ~*~ #
    _linear_terms    = Dict{Symbol,Float64}(:x => 1.0, :y => 1.0)
    _quadratic_terms = Dict{Tuple{Symbol,Symbol},Float64}((:x, :y) => -2.0)
    linear_terms     = Dict{Float64,Int}(1 => 1.0, 2 => 1.0)
    quadratic_terms  = Dict{Tuple{Int,Int},Float64}((1, 2) => -2.0)

    variable_map = Dict{Symbol,Int}(:x => 1, :y => 2)
    variable_inv = Dict{Int,Symbol}(1 => :x, 2 => :y)
    variables    = Symbol[:x, :y]
    variable_set = Set{Symbol}([:x, :y])

    scale  = 2.0
    offset = 1.0

    id          = 33
    version     = v"2.0.0"
    description = """
    This model is a test one.
    The end.
    """

    metadata = Dict{String,Any}(
        "type" => "test_model",
    )
    
    sampleset_samples = [
        QUBOTools.Sample([0, 0], 2.0, 1),
        QUBOTools.Sample([0, 1], 4.0, 1),
        QUBOTools.Sample([1, 0], 4.0, 1),
        QUBOTools.Sample([1, 1], 2.0, 1),
    ]

    sampleset_metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "total" => 2.0,
            "sample" => 1.0,
        )
    )

    solution = QUBOTools.SampleSet{Float64,Int}(
        sampleset_samples,
        sampleset_metadata,
    )

    std_model = QUBOTools.Model{V,T,U}(
        _linear_terms,
        _quadratic_terms;
        scale       = scale,
        offset      = offset,
        domain      = 𝔹,
        id          = id,
        version     = version,
        description = description,
        metadata    = metadata,
        solution    = solution
    )

    @testset "Standard" verbose = true begin
        @testset "Data access" verbose = true begin
            @test QUBOTools.linear_terms(std_model) == linear_terms
            @test QUBOTools.quadratic_terms(std_model) == quadratic_terms

            @test QUBOTools.variable_map(std_model) == variable_map
            @test QUBOTools.variable_map(std_model, :x) == 1
            @test QUBOTools.variable_map(std_model, :y) == 2

            @test QUBOTools.variable_inv(std_model) == variable_inv
            @test QUBOTools.variable_inv(std_model, 1) == :x
            @test QUBOTools.variable_inv(std_model, 2) == :y

            @test QUBOTools.variables(std_model) == variables
            @test QUBOTools.variable_set(std_model) == variable_set

            @test QUBOTools.scale(std_model) == scale
            @test QUBOTools.offset(std_model) == offset

            @test QUBOTools.id(std_model) == id
            @test QUBOTools.version(std_model) == version
            @test QUBOTools.description(std_model) == description
        end

        @testset "Queries" verbose = true begin
            @test QUBOTools.domain(std_model)      == 𝔹
            @test QUBOTools.dimension(std_model) == 2

            @test QUBOTools.linear_size(std_model)    == 2
            @test QUBOTools.quadratic_size(std_model) == 1

            @test QUBOTools.linear_density(std_model)    ≈ 1.0
            @test QUBOTools.quadratic_density(std_model) ≈ 1.0
            @test QUBOTools.density(std_model)           ≈ 1.0
        end

        @testset "Copy" verbose = true begin
            let model = copy(std_model)
                @test QUBOTools.linear_terms(model)    == QUBOTools.linear_terms(std_model)
                @test QUBOTools.quadratic_terms(model) == QUBOTools.quadratic_terms(std_model)
                @test QUBOTools.variable_map(model)    == QUBOTools.variable_map(std_model)
                @test QUBOTools.variable_inv(model)    == QUBOTools.variable_inv(std_model)
                @test QUBOTools.variables(model)       == QUBOTools.variables(std_model)
                @test QUBOTools.scale(model)           == QUBOTools.scale(std_model)
                @test QUBOTools.offset(model)          == QUBOTools.offset(std_model)
                @test QUBOTools.id(model)              == QUBOTools.id(std_model)
            end

            let model = QUBOTools.Model{V,T,U}()
                copy!(model, std_model)
                @test QUBOTools.linear_terms(model)    == QUBOTools.linear_terms(std_model)
                @test QUBOTools.quadratic_terms(model) == QUBOTools.quadratic_terms(std_model)
                @test QUBOTools.variable_map(model)    == QUBOTools.variable_map(std_model)
                @test QUBOTools.variable_inv(model)    == QUBOTools.variable_inv(std_model)
                @test QUBOTools.variables(model)       == QUBOTools.variables(std_model)
                @test QUBOTools.scale(model)           == QUBOTools.scale(std_model)
                @test QUBOTools.offset(model)          == QUBOTools.offset(std_model)
                @test QUBOTools.id(model)              == QUBOTools.id(std_model)
            end
        end

        @testset "Reset" verbose = true begin
            @test !isempty(std_model)
            empty!(std_model)
            @test isempty(std_model)
        end
    end
end