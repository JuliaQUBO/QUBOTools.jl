function test_form_dict()
    @testset "Dict Form" begin
        
    end

    return nothing
end

function test_form_dense()
    @testset "Dense Form" begin
        
    end

    return nothing
end

function test_form_sparse()
    @testset "Sparse Form" begin
        
    end

    return nothing
end

function test_form()
    @testset "→ Form" begin
        test_form_dict()
        test_form_dense()
        test_form_sparse()
    end
    
    return nothing
end
