module PropertyDicts

export PropertyDict

struct PropertyDict{K, V, T <: AbstractDict{K, V}} <: AbstractDict{K, V}
    d::T
    PropertyDict(d::T) where {T <: AbstractDict} =
        new{keytype(d), valtype(d), T}(d)
end

function Base.getproperty(d::PropertyDict, n::Symbol)
    v = get(d, n, Base.secret_table_token)

    if v != Base.secret_table_token
        return v
    end

    return getindex(d, String(n))
end

Base.convert(::Type{Any}, d::PropertyDict) = d
Base.convert(::Type{PropertyDict{K,V,T}}, d::PropertyDict{K,V,T}) where {K,V,T<:AbstractDict{K,V}} = d
Base.convert(::Type{T}, d::PropertyDict) where T <: AbstractDict = T === AbstractDict ? d : convert(T, PropertyDicts.unwrap(d))
Base.convert(::Type{T}, d::PropertyDict) where T = convert(T, PropertyDicts.unwrap(d))

Base.get(d::PropertyDict, k, default) = get(unwrap(d), k, default)

Base.getindex(d::PropertyDict, i) = getindex(unwrap(d), i)

Base.getproperty(d::PropertyDict, n) = getindex(d, n)
Base.getproperty(d::PropertyDict{AbstractString}, n::Symbol) = getindex(d, String(n))

Base.iterate(d::PropertyDict) = iterate(unwrap(d))
Base.iterate(d::PropertyDict, i) = iterate(unwrap(d), i)

Base.IteratorSize(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorSize(T)
Base.IteratorEltype(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorEltype(T)

Base.length(d::PropertyDict) = length(unwrap(d))

Base.string(d::PropertyDict) = string(unwrap(d))

unwrap(d::PropertyDict) = getfield(d, :d)

end # module PropertyDicts
