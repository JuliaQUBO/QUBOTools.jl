function test_swap_sense()
    T = Float64

    @test isnothing(QUBOTools.swap_sense(nothing))

    dict1 = Dict{Int,Float64}(
        5 => 10,
        6 => 11,
        7 => 12
    )

    swapped_dict1 = Dict{Int,Float64}(
        5 => -10,
        6 => -11,
        7 => -12
    )

    @test QUBOTools.swap_sense(dict1) == swapped_dict1

    dict2 = Dict{Tuple{Int,Int}, Float64}(
        (1,1) => 1.0,
        (2,2) => 2.0,
        (3,3) => 3.0
    )

    swapped_dict2 = Dict{Tuple{Int,Int}, Float64}(
        (1,1) => -1.0,
        (2,2) => -2.0,
        (3,3) => -3.0
    )

    @test QUBOTools.swap_sense(dict2) == swapped_dict2


    sampletest = QUBOTools.Sample([0,1], 5.0, 3)
    swappedsample = QUBOTools.swap_sense(sampletest)

    @test QUBOTools.value(sampletest) == - QUBOTools.value(swappedsample)


    V = Symbol
    U = Int
    T = Float64

    bool_states = [[0, 1], [0, 0], [1, 0], [1, 1]]

    reads       = [     2,      1,      3,      4]
    values      = [   0.0,    2.0,    4.0,    6.0]
    bool_samples1 = [QUBOTools.Sample(s...) for s in zip(bool_states, values, reads)]
    bool_samples2 = [QUBOTools.Sample(s...) for s in zip(bool_states, -values, reads)]

    model1 = QUBOTools.Model{𝔹,V,T,U}(
            Dict{V,T}(:x => 1.0, :y => -1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 2.0);
            scale       = 2.0,
            offset      = 1.0,
            id          = 1,
            version     = v"0.1.0",
            description = "This is a Bool ModelWrapper",
            metadata    = Dict{String,Any}(
                "meta" => "data",
                "type" => "bool",
            ),
            sampleset   = QUBOTools.SampleSet(bool_samples1),
        )
    

    swappedmodel1 = QUBOTools.swap_sense(:max, model1)
    
    @test QUBOTools.offset(swappedmodel1) == - QUBOTools.offset(model1)
    @test first(QUBOTools.qubo(swappedmodel1,Matrix)) == - first(QUBOTools.qubo(model1,Matrix))

end

function test_generic()
    test_swap_sense()
end