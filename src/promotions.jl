Base.promote_rule(::Type{C3}, ::Type{Cgray}) where {C3<:Color3,Cgray<:AbstractGray} = base_colorant_type(C3){promote_type(eltype(C3), eltype(Cgray))}
Base.promote_rule(::Type{C3}, ::Type{Cagray}) where {C3<:Color3,Cagray<:AbstractAGray} = alphacolor(base_colorant_type(C3)){promote_type(eltype(C3), eltype(Cagray))}
Base.promote_rule(::Type{C3}, ::Type{Cgraya}) where {C3<:Color3,Cgraya<:AbstractGrayA} = coloralpha(base_colorant_type(C3)){promote_type(eltype(C3), eltype(Cgraya))}

Base.promote_rule(::Type{C3}, ::Type{Cgray}) where {C3<:Transparent3,Cgray<:AbstractGray} = base_colorant_type(C3){promote_type(eltype(C3), eltype(Cgray))}
Base.promote_rule(::Type{C3}, ::Type{Cgray}) where {C3<:Transparent3,Cgray<:TransparentGray} = base_colorant_type(C3){promote_type(eltype(C3), eltype(Cgray))}
