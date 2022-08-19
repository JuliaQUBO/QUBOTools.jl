function Base.show(io::IO, model::AbstractQUBOModel)
    println(
        io,
        """
        $(QUBOTools.model_name(model)) Model:
        $(QUBOTools.domain_size(model)) variables [$(QUBOTools.domain_name(model))]
        """
    )

    if !isempty(model)
        print(
            io,
            """
            Density:
            linear    ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.linear_density(model)))%
            quadratic ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.quadratic_density(model)))%
            total     ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.density(model)))%"""
        )
    else
        print(
            io,
            """
            The model is empty"""
        )
    end
end