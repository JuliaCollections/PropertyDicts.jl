module PropertyDicts

export PropertyDict

struct PropertyDict{K, V, T <: AbstractDict{K, V}} <: AbstractDict{K, V}
    d::T

    PropertyDict(@nospecialize pd::PropertyDict) = pd
    PropertyDict(d::T) where {T <: AbstractDict} = new{keytype(d), valtype(d), T}(d)
    PropertyDict(args...) = PropertyDict(Dict(args...))
end

unwrap(pd::PropertyDict) = getfield(pd, :d)

function Base.sizehint!(pd::PropertyDict, n::Integer)
    sizehint!(getfield(pd, :d), n)
    return pd
end

Base.push!(pd::PropertyDict, p::Pair) = push!(getfield(pd, :d), p)
Base.pop!(pd::PropertyDict, args...) = pop!(getfield(pd, :d), args...)
function Base.empty!(pd::PropertyDict)
    empty!(getfield(pd, :d))
    return pd
end
function Base.delete!(pd::PropertyDict, key)
    delete!(getfield(pd, :d), key)
    return pd
end

Base.getproperty(pd::PropertyDict, n::Symbol) = getindex(pd, n)
Base.getproperty(pd::PropertyDict, n::String) = getindex(pd, n)

Base.setproperty!(pd::PropertyDict, n::Symbol, v) = setindex!(pd, v, n)
Base.setproperty!(pd::PropertyDict, n::String, v) = setindex!(pd, v, n)

Base.get(pd::PropertyDict, k, default) = get(getfield(pd, :d), k, default)
Base.get(pd::PropertyDict{Symbol}, k::AbstractString, default) = get(pd, Symbol(k), default)
Base.get(pd::PropertyDict{<:AbstractString}, k::Symbol, default) = get(pd, String(k), default)
function Base.get(pd::PropertyDict{Any}, k::Symbol, default)
    out = get(getfield(pd, :d), k, Base.secret_table_token)
    if out === Base.secret_table_token
        return get(getfield(pd, :d), String(k), default)
    else
        return out
    end
end
function Base.get(pd::PropertyDict{Any}, k::String, default)
    out = get(getfield(pd, :d), k, Base.secret_table_token)
    if out === Base.secret_table_token
        return get(getfield(pd, :d), Symbol(k), default)
    else
        return out
    end
end

function Base.get(f::Union{Function,Type}, pd::PropertyDict, k)
    out = get(pd, k, Base.secret_table_token)
    if out === Base.secret_table_token
        return f()
    else
        return out
    end
end

Base.get!(pd::PropertyDict, k, default) = get!(getfield(pd, :d), k, default)
Base.get!(pd::PropertyDict{Symbol}, k::AbstractString, default) = get!(pd, Symbol(k), default)
Base.get!(pd::PropertyDict{<:AbstractString}, k::Symbol, default) = get!(pd, String(k), default)
function Base.get!(f::Union{Function,Type}, pd::PropertyDict, k)
    out = get(pd, k, Base.secret_table_token)
    if out === Base.secret_table_token
        default = f()
        setindex!(pd, default, k)
        return default
    else
        return out
    end
end

function Base.getindex(pd::PropertyDict, k)
    out = get(pd, k, Base.secret_table_token)
    out === Base.secret_table_token && throw(KeyError(k))
    return out
end

Base.setindex!(pd::PropertyDict, v, i) = setindex!(getfield(pd, :d), v, i)
Base.setindex!(pd::PropertyDict{<:AbstractString}, v, i::Symbol) = setindex!(pd, v, String(i))
Base.setindex!(pd::PropertyDict{Symbol}, v, i::AbstractString) = setindex!(pd, v, Symbol(i))

Base.iterate(pd::PropertyDict) = iterate(getfield(pd, :d))
Base.iterate(pd::PropertyDict, i) = iterate(getfield(pd, :d), i)

Base.IteratorSize(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorSize(T)
Base.IteratorEltype(::Type{PropertyDict{K,V,T}}) where {K,V,T} = Base.IteratorEltype(T)

Base.length(pd::PropertyDict) = length(getfield(pd, :d))

Base.string(pd::PropertyDict) = string(getfield(pd, :d))

@static if isdefined(Base, :hasproperty)
    Base.hasproperty(pd::PropertyDict, key::Symbol) = haskey(pd, key)
    Base.hasproperty(pd::PropertyDict, key) = haskey(pd, key)
end
Base.haskey(pd::PropertyDict, key) = haskey(getfield(pd, :d), key)
Base.haskey(pd::PropertyDict{<:AbstractString}, key::Symbol) = haskey(pd, String(key))
Base.haskey(pd::PropertyDict{Symbol}, key::AbstractString) = haskey(pd, Symbol(key))
function Base.haskey(pd::PropertyDict{Any}, key::AbstractString)
    haskey(getfield(pd, :d), key) || haskey(getfield(pd, :d), Symbol(key))
end
function Base.haskey(pd::PropertyDict{Any}, key::Symbol)
    haskey(getfield(pd, :d), key) || haskey(getfield(pd, :d), String(key))
end

# a handful of dictionaries aren't just wrapped in `KeySet` and `ValueIterator`
Base.keys(pd::PropertyDict) = keys(getfield(pd, :d))
Base.values(pd::PropertyDict) = values(getfield(pd, :d))

Base.propertynames(pd::PropertyDict) = keys(pd)

end # module PropertyDicts
