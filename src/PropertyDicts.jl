module PropertyDicts

export PropertyDict

struct PropertyDict{K, V, T <: AbstractDict{K, V}} <: AbstractDict{K, V}
    d::T

    PropertyDict(d::T) where {T <: AbstractDict} = new{keytype(d), valtype(d), T}(d)
    PropertyDict(args...) = PropertyDict(Dict(args...))
end

Base.getproperty(d::PropertyDict, n::Symbol) = getindex(d, n)
Base.getproperty(d::PropertyDict, n::String) = getindex(d, n)

Base.setproperty!(d::PropertyDict, n::Symbol, v) = setindex!(d, v, n)
Base.setproperty!(d::PropertyDict, n::String, v) = setindex!(d, v, n)

Base.convert(::Type{Any}, d::PropertyDict) = d
Base.convert(::Type{PropertyDict{K,V,T}}, d::PropertyDict{K,V,T}) where {K,V,T<:AbstractDict{K,V}} = d
Base.convert(::Type{T}, d::PropertyDict) where T <: AbstractDict = T === AbstractDict ? d : convert(T, PropertyDicts.unwrap(d))
Base.convert(::Type{T}, d::PropertyDict) where T = convert(T, PropertyDicts.unwrap(d))

Base.get(d::PropertyDict, k, default) = get(unwrap(d), k, default)
Base.get(d::PropertyDict{Symbol}, k::AbstractString, default) = get(d, Symbol(k), default)
Base.get(d::PropertyDict{<:AbstractString}, k::Symbol, default) = get(d, String(k), default)
function Base.get(d::PropertyDict{Any}, k::Symbol, default)
    out = get(unwrap(d), k, Base.secret_table_token)
    if out === Base.secret_table_token
        return get(unwrap(d), String(k), default)
    else
        return out
    end
end
function Base.get(d::PropertyDict{Any}, k::String, default)
    out = get(unwrap(d), k, Base.secret_table_token)
    if out === Base.secret_table_token
        return get(unwrap(d), Symbol(k), default)
    else
        return out
    end
end

function Base.get(f::Union{Function,Type}, d::PropertyDict, k)
    out = get(d, k, Base.secret_table_token)
    if out === Base.secret_table_token
        return f()
    else
        return out
    end
end

Base.get!(d::PropertyDict, k, default) = get!(unwrap(d), k, default)
Base.get!(d::PropertyDict{Symbol}, k::AbstractString, default) = get!(d, Symbol(k), default)
Base.get!(d::PropertyDict{<:AbstractString}, k::Symbol, default) = get!(d, String(k), default)
function Base.get!(f::Union{Function,Type}, d::PropertyDict, k)
    out = get(d, k, Base.secret_table_token)
    if out === Base.secret_table_token
        return setindex!(d, f(), k)
    else
        return out
    end
end

function Base.getindex(d::PropertyDict, k)
    out = get(d, k, Base.secret_table_token)
    out === Base.secret_table_token && throw(KeyError(k))
    return out
end

Base.setindex!(d::PropertyDict, v, i) = setindex!(unwrap(d), v, i)
Base.setindex!(d::PropertyDict{<:AbstractString}, v, i::Symbol) = setindex!(d, v, String(i))
Base.setindex!(d::PropertyDict{Symbol}, v, i::AbstractString) = setindex!(d, v, Symbol(i))

Base.iterate(d::PropertyDict) = iterate(unwrap(d))
Base.iterate(d::PropertyDict, i) = iterate(unwrap(d), i)

Base.IteratorSize(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorSize(T)
Base.IteratorEltype(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorEltype(T)

Base.length(d::PropertyDict) = length(unwrap(d))

Base.string(d::PropertyDict) = string(unwrap(d))

# a handful of dictionaries aren't just wrapped in `KeySet` and `ValueIterator`
Base.keys(d::PropertyDict) = keys(unwrap(d))
Base.values(d::PropertyDict) = values(unwrap(d))

Base.propertynames(d::PropertyDict) = keys(d)

unwrap(d::PropertyDict) = getfield(d, :d)

end # module PropertyDicts
