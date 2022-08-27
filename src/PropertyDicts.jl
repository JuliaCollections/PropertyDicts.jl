module PropertyDicts

export PropertyDict

struct PropertyDict{K<:Union{String,Symbol}, V, D <: Union{AbstractDict,NamedTuple}} <: AbstractDict{K, V}
    d::D

    PropertyDict(@nospecialize pd::PropertyDict) = pd
    PropertyDict(d::AbstractDict{String,V}) where {V} = new{String,V,typeof(d)}(d)
    PropertyDict(d::AbstractDict{Symbol,V}) where {V} = new{Symbol,V,typeof(d)}(d)
    PropertyDict(nt::NamedTuple) = new{Symbol,eltype(nt),typeof(nt)}(nt)
    function PropertyDict(d::AbstractDict)
        dsym = Dict{Symbol,valtype(d)}()
        for (k,v) in d
            dsym[Symbol(k)] = v
        end
        PropertyDict(dsym)
    end
    PropertyDict(args...) = PropertyDict(Dict(args...))
end

Base.isempty(pd::PropertyDict) = isempty(getfield(pd, :d))

Base.IteratorSize(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorSize(fieldtype(T, :d))
Base.IteratorEltype(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorEltype(eltype(T))

Base.length(pd::PropertyDict) = length(getfield(pd, :d))

function Base.sizehint!(pd::PropertyDict, n::Integer)
    sizehint!(getfield(pd, :d), n)
    return pd
end

_tokey(@nospecialize(pd::PropertyDict{String}), k::AbstractString) = k
_tokey(@nospecialize(pd::PropertyDict{String}), k) = String(k)
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k::Symbol) = k
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k) = Symbol(k)

Base.pop!(pd::PropertyDict, k) = pop!(getfield(pd, :d), _tokey(pd, k))
Base.pop!(pd::PropertyDict, k, d) = pop!(getfield(pd, :d), _tokey(pd, k), d)

function Base.empty!(pd::PropertyDict)
    empty!(getfield(pd, :d))
    return pd
end
function Base.delete!(pd::PropertyDict, k)
    delete!(getfield(pd, :d), _tokey(pd, k))
    return pd
end
Base.empty(pd::PropertyDict) = PropertyDict(empty(getfield(pd, :d)))

Base.get(pd::PropertyDict, k, d) = get(getfield(pd, :d), _tokey(pd, k), d)
function Base.get(f::Union{Function,Type}, pd::PropertyDict, k)
    get(f, getfield(pd, :d), _tokey(pd, k))
end
Base.get!(pd::PropertyDict, k, d) = get!(getfield(pd, :d), _tokey(pd, k), d)
function Base.get!(f::Union{Function,Type}, pd::PropertyDict, k)
    get!(f, getfield(pd, :d), _tokey(pd, k))
end

Base.@propagate_inbounds function Base.getindex(pd::PropertyDict{Symbol,V,<:NamedTuple}, k::Symbol) where {V}
    getfield(getfield(pd, :d), k)
end
Base.@propagate_inbounds function Base.getindex(pd::PropertyDict, k)
    getindex(getfield(pd, :d), _tokey(pd, k))
end
Base.@propagate_inbounds function Base.setindex!(pd::PropertyDict, v, k)
    setindex!(getfield(pd, :d), v, _tokey(pd, k))
end

Base.haskey(pd::PropertyDict, k) = haskey(getfield(pd, :d), _tokey(pd, k))

Base.getkey(pd::PropertyDict, k, d) = getkey(getfield(pd, :d), _tokey(pd, k), d)

Base.reverse(pd::PropertyDict) = PropertyDict(getfield(pd, :d))

@inline function Base.iterate(pd::PropertyDict{Symbol,V,<:NamedTuple}) where {V}
    if isempty(pd)
        nothing
    else
        Pair{Symbol,V}(getfield(keys(pd), 1), getfield(getfield(pd, :d), 1)), 2
    end
end
@inline function Base.iterate(pd::PropertyDict{Symbol,V,<:NamedTuple}, s::Int) where {V}
    if length(pd) < s
        nothing
    else
        Pair{Symbol,V}(getfield(keys(getfield(pd, :d)), s), getfield(getfield(pd, :d), s)), s + 1
    end
end
Base.iterate(pd::PropertyDict) = iterate(getfield(pd, :d))
Base.iterate(pd::PropertyDict, i) = iterate(getfield(pd, :d), i)

# a handful of dictionaries aren't just wrapped in `KeySet` and `ValueIterator`
Base.keys(pd::PropertyDict) = keys(getfield(pd, :d))
Base.values(pd::PropertyDict) = values(getfield(pd, :d))

## property methods
function Base.getproperty(pd::PropertyDict{Symbol,V,<:NamedTuple}, k::Symbol) where {V}
    getfield(getfield(pd, :d), k)
end
Base.getproperty(pd::PropertyDict, k::Symbol) = getindex(pd, k)
Base.getproperty(pd::PropertyDict, k::String) = getindex(pd, k)

Base.setproperty!(pd::PropertyDict, k::Symbol, v) = setindex!(pd, v, k)
Base.setproperty!(pd::PropertyDict, k::String, v) = setindex!(pd, v, k)

Base.propertynames(pd::PropertyDict) = keys(getfield(pd, :d))

@static if isdefined(Base, :hasproperty)
    Base.hasproperty(pd::PropertyDict, k::Symbol) = haskey(pd, _tokey(pd, k))
    Base.hasproperty(pd::PropertyDict, k) = haskey(pd, _tokey(pd, k))
end

Base.copy(pd::PropertyDict{Symbol,<:Any,<:NamedTuple}) = pd
Base.copy(pd::PropertyDict) = PropertyDict(copy(getfield(pd, :d)))

_promote_key(::Type{String}, ::Type{String}) = String
_promote_key(::Type{Symbol}, ::Type{Symbol}) = Symbol
_promote_key(::Type{Symbol}, ::Type{String}) = Symbol
_promote_key(::Type{String}, ::Type{Symbol}) = Symbol
_promote_keytypes(K::Union{Type{String},Type{Symbol}}) = K
function _promote_keytypes(K::Union{Type{String},Type{Symbol}}, d, ds...)
    _promote_valtypes(_promote_key(K, keytype(d)), ds...)
end
_promote_valtypes(V) = V
function _promote_valtypes(V, d, ds...)  # give up if promoted to any
    V === Any ? Any : _promote_valtypes(promote_type(V, valtype(d)), ds...)
end

## merge
Base.merge(pd::PropertyDict) = copy(pd)
function Base.merge(pd::PropertyDict, others::PropertyDict...)
    K = _promote_keytypes(keytype(pd), others...)
    V = _promote_valtypes(valtype(pd), others...)
    out = PropertyDict(Dict{K,V}())
    for (k, v) in pairs(getfield(pd, :d))
        out[k] = v
    end
    merge!(out, others...)
end
function Base.merge(x::PropertyDict{Symbol,<:Any,<:NamedTuple}, y::PropertyDict{Symbol,<:Any,<:NamedTuple}, zs::PropertyDict{Symbol,<:Any,<:NamedTuple}...)
    merge(merge(x, y), zs...)
end
function Base.merge(x::PropertyDict{Symbol,<:Any,<:NamedTuple}, y::PropertyDict{Symbol,<:Any,<:NamedTuple})
    PropertyDict(merge(getfield(x, :d), getfield(y, :d)))
end

## mergewith
Base.mergewith(combine, pd::PropertyDict) = copy(pd)
function Base.mergewith(combine, pd::PropertyDict, others::PropertyDict...)
    K = _promote_keytypes(keytype(pd), others...)
    V = _promote_valtypes(valtype(pd), others...)
    out = PropertyDict(Dict{K,promote_type(Core.Compiler.return_type(combine, Tuple{V,V}), V)}())
    for (k, v) in pd
        out[k] = v
    end
    mergewith!(combine, out, others...)
end
function Base.mergewith(combine, x::PropertyDict{Symbol,<:Any,<:NamedTuple}, y::PropertyDict{Symbol,<:Any,<:NamedTuple}, zs::PropertyDict{Symbol,<:Any,<:NamedTuple}...)
    _mergewith(combine, getfield(x, :d), getfield(y, :d))
end
function Base.mergewith(combine, x::PropertyDict{Symbol,<:Any,<:NamedTuple}, y::PropertyDict{Symbol,<:Any,<:NamedTuple})
    _mergewith(combine, getfield(x, :d), getfield(y, :d))
end
function _mergewith(combine, a::NamedTuple{an}, b::NamedTuple{bn}) where {an, bn}
    if @generated
        names = Base.merge_names(an, bn)
        t = Expr(:tuple)
        for n in names
            if Base.sym_in(n, an)
                if Base.sym_in(n, bn)
                    push!(t.args, :(combine(getfield(a, $(QuoteNode(n))), getfield(b, $(QuoteNode(n))))))
                else
                    push!(t.args, :(getfield(a, $(QuoteNode(n)))))
                end
            else
                push!(t.args, :(getfield(b, $(QuoteNode(n)))))
            end
        end
        :(NamedTuple{$names}($(t)))
    else
        names = Base.merge_names(an, bn)
        NamedTuple{names}(ntuple(Val{nfields(names)}()) do i
            n = getfield(names, i)
            if Base.sym_in(n, an)
                if Base.sym_in(n, bn)
                    combine(getfield(a, n), getfield(b, n))
                else
                    getfield(a, n)
                end
            else
                getfield(b, n)
            end
        end)
    end
end

end # module PropertyDicts
