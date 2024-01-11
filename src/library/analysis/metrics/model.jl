function density(x)
    n = dimension(x)

    if n == 0
        return NaN
    else
        ls = linear_size(x)
        qs = quadratic_size(x)

        return (2 * qs + ls) / (n * n)
    end
end

function linear_density(x)
    n = dimension(x)

    if n == 0
        return NaN
    else
        ls = linear_size(x)

        return ls / n
    end
end

function quadratic_density(x)
    n = dimension(x)

    if n <= 1
        return NaN
    else
        qs = quadratic_size(x)

        return (2 * qs) / (n * (n - 1))
    end
end
