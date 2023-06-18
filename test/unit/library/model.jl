function test_model()
    @testset "Model" begin
        @testset "Constructors" begin
            let V = Symbol, T = Float64, U = Int
                model = QUBOTools.Model{V,T,U}(
                    
                )

            end
        end
    end

    return nothing
end
