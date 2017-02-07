Base.promote_rule{C3<:Color3,Cgray<:AbstractGray}(::Type{C3}, ::Type{Cgray}) = base_colorant_type(C3){promote_type(eltype(C3), eltype(Cgray))}
Base.promote_rule{C3<:Color3,Cagray<:AbstractAGray}(::Type{C3}, ::Type{Cagray}) = alphacolor(base_colorant_type(C3)){promote_type(eltype(C3), eltype(Cagray))}
Base.promote_rule{C3<:Color3,Cgraya<:AbstractGrayA}(::Type{C3}, ::Type{Cgraya}) = coloralpha(base_colorant_type(C3)){promote_type(eltype(C3), eltype(Cgraya))}

Base.promote_rule{C4<:Transparent4,Cgray<:AbstractGray}(::Type{C4}, ::Type{Cgray}) = base_colorant_type(C4){promote_type(eltype(C4), eltype(Cgray))}
Base.promote_rule{C4<:Transparent4,Cgray<:TransparentGray}(::Type{C4}, ::Type{Cgray}) = base_colorant_type(C4){promote_type(eltype(C4), eltype(Cgray))}
