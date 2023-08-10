# Here, specialized methods for comparing models & solutions are provided.
# The idea is not to put a big burden into the Base operators (==, isapprox)

function compare_model(src::Model{V,T,U}, dst::Model{V,T,U};) where {V,T,U}
    return nothing
end
