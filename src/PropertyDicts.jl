module PropertyDicts

export PropertyDict

struct PropertyDict{K, V, T <: AbstractDict{K, V}} <: AbstractDict{K, V}
    d::T

    PropertyDict(d::T) where {T <: AbstractDict} = new{keytype(d), valtype(d), T}(d)
    PropertyDict(args...) = PropertyDict(Dict(args...))
end

unwrap(d::PropertyDict) = getfield(d, :d)

function Base.sizehint!(d::PropertyDict, n::Integer)
    sizehint!(unwrap(d), n)
    return d
end

Base.push!(d::PropertyDict, p::Pair) = push!(unwrap(d), p)
Base.pop!(d::PropertyDict, args...) = pop!(unwrap(d), args...)
function Base.empty!(d::PropertyDict)
    empty!(unwrap(d))
    return d
end
function Base.delete!(d::PropertyDict, key)
    delete!(unwrap(d), key)
    return d
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
        default = f()
        setindex!(d, default, k)
        return default
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

@static if isdefined(Base, :hasproperty)
    Base.hasproperty(d::PropertyDict, key::Symbol) = haskey(d, key)
    Base.hasproperty(d::PropertyDict, key) = haskey(d, key)
end
Base.haskey(d::PropertyDict, key) = haskey(unwrap(d), key)
Base.haskey(d::PropertyDict{<:AbstractString}, key::Symbol) = haskey(d, String(key))
Base.haskey(d::PropertyDict{Symbol}, key::AbstractString) = haskey(d, Symbol(key))
function Base.haskey(d::PropertyDict{Any}, key::AbstractString)
    haskey(unwrap(d), key) || haskey(unwrap(d), Symbol(key))
end
function Base.haskey(d::PropertyDict{Any}, key::Symbol)
    haskey(unwrap(d), key) || haskey(unwrap(d), String(key))
end

# a handful of dictionaries aren't just wrapped in `KeySet` and `ValueIterator`
Base.keys(d::PropertyDict) = keys(unwrap(d))
Base.values(d::PropertyDict) = values(unwrap(d))

Base.propertynames(d::PropertyDict) = keys(d)

end # module PropertyDicts
