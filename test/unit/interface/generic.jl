

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


end

function test_generic()
    test_swap_sense()
end