using OrderedCollections: OrderedDict
using PropertyDicts
using Test

@testset "constructors" begin
    @test isa(PropertyDict{Symbol}(PropertyDict(foo = 1, bar = 2)), PropertyDict{Symbol})
    @test isa(PropertyDict{Symbol,Int}(PropertyDict(foo = 1, bar = 2)), PropertyDict{Symbol,Int})
    @test isa(PropertyDict{Symbol,Int}(PropertyDict(foo = 1, bar = 2)), PropertyDict{Symbol, Int64, NamedTuple{(:foo, :bar), Tuple{Int64, Int64}}})
    @test isa(PropertyDict{Symbol,Int}(foo = 1, bar = 2.0), PropertyDict{Symbol, Int64, NamedTuple{(:foo, :bar), Tuple{Int64, Int64}}})
    @test isa(PropertyDict{Symbol,Int}(foo = 1, bar = 2.0), PropertyDict{Symbol,Int})
    @test isa(PropertyDict{Symbol,Int}(Dict{Symbol,Int}()), PropertyDict{Symbol,Int})
    @test isa(PropertyDict{Symbol,Int}(PropertyDict{Symbol}(foo = 1, bar = 2.0)), PropertyDict{Symbol,Int})
    @test isa(PropertyDict{Symbol,Int}(Dict(:foo => 1, :bar => 2)), PropertyDict{Symbol,Int})

    @test isa(PropertyDict{String}("foo" => 1, "bar" => 2, "buz" => 3), PropertyDict{String,Int,Dict{String,Int}})
    @test isa(PropertyDict{String,Int}(Dict("foo" => 1, "bar" => 2)), PropertyDict{String,Int,Dict{String,Int}})
    @test isa(PropertyDict{String}(PropertyDict{String,Int}("foo" => 1, "bar" => 2)), PropertyDict{String,Int,Dict{String,Int}})
    @test isa(PropertyDict{String,Int}(PropertyDict{String,Int}(Dict("foo" => 1, "bar" => 2))), PropertyDict{String,Int,Dict{String,Int}})
end

#  PropertyDict{K,V}(arg, args...) where {K,V} = PropertyDict{K,V}(Dict(arg, args...))
#  PropertyDict{String}(@nospecialize(pd::PropertyDict{String})) = pd


d = Dict("foo"=>1, :bar=>2)
_keys = collect(keys(d))
pd = PropertyDict(d)

str_props = PropertyDict("foo" => 1, "bar" => 2)
sym_props = PropertyDict(:foo => 1, :bar => 2)

nt = (d =1, )
ntpd = PropertyDict(nt)

@test length(pd) == length(d)

@test values(PropertyDict(ntpd)) === values(nt)


@test empty!(PropertyDict(Dict("foo"=>1, :bar=>2))) isa PropertyDict
@test empty(pd) == PropertyDict(empty(d))

@test propertynames(PropertyDict(ntpd)) === propertynames(nt)

@test ntpd.d === nt.d
@test keys(PropertyDict(ntpd)) === keys(nt)
@test hasproperty(sym_props, "bar")
@test keytype(str_props) <: String
@test keytype(sym_props) <: Symbol
@test hasproperty(str_props, :bar)
@test hasproperty(pd, :foo)
@test hasproperty(pd, "bar")
@test haskey(pd, :foo)
@test getkey(pd, :buz, nothing) === nothing

@testset "convert" begin
    expected = OrderedDict
    result = convert(expected, pd)

    @test result isa expected
end

@testset "get" begin
    @testset "default value" begin
        default = "baz"

        @test get(pd, "DNE", default) == default
        @test get(() -> 3, str_props, :foo) == 1
        @test get(() -> 3, str_props, :baz) == 3
        @test get(str_props, :baz, 3) == 3
        @test get(sym_props, "baz", 3) == 3
        @test get!(str_props, :baz, 3) == 3
        @test get!(sym_props, "baz", 3) == 3
        @test get!(() -> 4, str_props, :baz) == 3
        @test get!(() -> 4, sym_props, "baz") == 3
        @test get!(() -> 4, sym_props, "buz") == 4
    end

    @testset "$(typeof(key))" for key in _keys
        @test get(pd, key, "DNE") == d[key]
    end
end

@testset "getindex - $key" for key in _keys
    @test getindex(pd, key) == getindex(d, key)
end

@testset "getproperty" begin
    @test pd.foo == 1
    @test pd.bar == 2
    sym_props."spam" = 4
    @test sym_props."spam" == 4

    str_props.spam = 4
    @test str_props.spam == 4
end

@testset "iterate" begin
    @test iterate(pd) == iterate(d)
    @test iterate(pd, 1) == iterate(d, 1)
    @test iterate(pd, 2) == iterate(d, 2)
end

@testset "iteratorsize" begin
    @test Base.IteratorSize(pd) == Base.IteratorSize(d)
end

@testset "iteratoreltype" begin
    @test Base.IteratorEltype(pd) == Base.IteratorEltype(d)
end

@test reverse(PropertyDict((a=1, b=2, c=3))) === PropertyDict(reverse((a=1, b=2, c=3)))

push!(pd, :buz => 10)
@test pop!(pd, :buz) == 10
@test pop!(pd, :buz, 20) == 20
@test sizehint!(pd, 5) === pd
@test get(pd, delete!(pd, "foo"), 10) == 10

@testset "NamedProperties" begin
    pd = PropertyDict(x=1)
    @test copy(pd) == pd
    @test empty(pd) === PropertyDict()
    @test pd[:x] == 1
end

@testset "merge & mergewith" begin
    a = PropertyDict((a=1, b=2, c=3))
    b = PropertyDict((b=4, d=5))
    c = PropertyDict((a=1, b=2))
    d = PropertyDict((b=3, c=(d=1,)))
    e = PropertyDict((c=(d=2,),))
    f = PropertyDict(Dict("foo"=>1, "bar"=>2))

    @test merge(a) === a
    @test f !== merge(f) == f
    @test @inferred(merge(a, b)) == PropertyDict((a = 1, b = 4, c = 3, d = 5))
    @test @inferred(merge(c, d, e)) == PropertyDict((a = 1, b = 3, c = (d = 2,)))
    @test merge(a, f, c) == merge(f, a, c)

    @test mergewith(+, a) == a
    @test mergewith(+, f) == PropertyDict(Dict("foo"=>1, "bar"=>2))
    @test mergewith(+, f, f) == PropertyDict(Dict("foo"=>2, "bar"=>4))
    @test mergewith(+, a, b) == PropertyDict(a=1, b=6, c=3, d=5)
    combiner(x, y) = "$(x) and $(y)"
    @test mergewith(combiner, a, f, c, PropertyDict()) ==
        PropertyDict(:a=>"1 and 1",  :b=>"2 and 2",  :c=>3,  :bar=>2, :foo=>1)
    @test @inferred(mergewith(combiner, a, b, c, PropertyDict())) ==
        PropertyDict((a = "1 and 1", b = "2 and 4 and 2", c = 3, d = 5))
end

@testset "setindex" begin
    npd = Base.setindex(Base.setindex(PropertyDict(), 1, :x), 2, :y)
    @test values(npd) == (1, 2)
    @test keys(npd) == (:x, :y)
end
