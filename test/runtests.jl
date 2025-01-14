using Lazy2
using Lazy2: cycle, range, drop, take
using Test

# dummy function to test threading macros on
function add_things(n1, n2, n3)
    100n1 + 10n2 + n3
end

# dummy macro to test threading macros on
macro m_add_things(n1, n2, n3)
    quote
        100 * $(esc(n1)) + 10 * $(esc(n2)) + $(esc(n3))
    end
end

# define structs for @forward macro testing below (PR #112)
struct Foo112 end
struct Bar112
    f::Foo112
end

@testset "Lazy2" begin
    if VERSION >= v"1.0.0"
        @test isempty(detect_ambiguities(Base, Core, Lazy2))
    end

    @testset "Lists" begin
        @test list(1, 2, 3)[2] == 2
        @test prepend(1, list(2, 3, 4)) == 1:list(2, 3, 4)
        @test seq([1, 2, 3]) == list(1, 2, 3)
        @test seq(1:3) == list(1, 2, 3)
        @test constantly(1)[50] == 1
        testfn() = 1
        @test repeatedly(testfn)[50] == 1
        @test cycle([1, 2, 3])[50] == 2
        @test iterated(x -> x^2, 2)[3] == 16
        @test range(1, 5)[3] == 3
        @test isnothing(range(1, 5)[10])
        @test range(1, 5)[-1] == 1
        @test list(1, 2, 3) * list(4, 5, 6) == list(1, 2, 3, 4, 5, 6)
        @test first(list(1, 2, 3)) == 1
        @test tail(list(1, 2, 3)) == list(2, 3)
        @test flatten(list(1, 2, list(3, 4))) == list(1, 2, 3, 4)
        @test list(1, 2, list(3, 4))[3] == list(3, 4)
        @test list(list(1), list(2))[1] == list(1)
        @test reductions(+, 0, list(1, 2, 3)) == list(1, 3, 6)
        @test [i for i in @lazy[1, 2, 3]] == [1, 2, 3]

        l = list(1, 2, 3)
        @test l:7:l == list(list(1, 2, 3), 7, 1, 2, 3)   # ambiguity test
    end

    @testset "Fibs" begin
        fibs = @lazy 0:1:(fibs + drop(1, fibs))
        @test fibs[20] == 4181
        @test take(5, fibs) == list(0, 1, 1, 2, 3)
    end

    @testset "Primes" begin
        isprime(n) = @>> primes begin
            take_while(x -> x <= sqrt(n))
            map(x -> n % x == 0)
            any
            !
        end
        primes = filter(isprime, range(2))
    end

    @testset "Even squares" begin
        esquares = @>> range() map(x -> x^2) filter(iseven)
        @test take(5, esquares) == list(4, 16, 36, 64, 100)
    end

    @testset "Threading macros" begin
        temp = @> [2 3] sum
        @test temp == 5
        # Reverse from after index 2
        temp = @>> 2 reverse([1, 2, 3, 4, 5])
        @test temp == [1, 5, 4, 3, 2]
        temp = @as x 2 begin
            x^2
            x + 2
        end
        @test temp == 6

        # test that threading macros work with functions
        temp = @> 1 add_things(2, 3)
        @test temp == 123

        temp = @>> 3 add_things(1, 2)
        @test temp == 123

        temp = @as x 2 add_things(1, x, 3)
        @test temp == 123

        # test that threading macros work with macros
        temp = @> 1 @m_add_things(2, 3)
        @test temp == 123

        temp = @>> 3 @m_add_things(1, 2)
        @test temp == 123

        temp = @as x 2 @m_add_things(1, x, 3)
        @test temp == 123
    end

    @testset "Forward macro" begin
        play(x::Foo112; y) = y                        # uses keyword arg
        play(x::Foo112, z) = z                        # uses regular arg
        play(x::Foo112, z1, z2; y) = y + z1 + z2      # uses both

        @forward Bar112.f play                        # forward `play` function to field `f`

        let f = Foo112(), b = Bar112(f)
            @test play(f, y = 1) === play(b, y = 1)
            @test play(f, 2) === play(b, 2)
            @test play(f, 2, 3, y = 1) === play(b, 2, 3, y = 1)
        end
    end

    @testset "getindex" begin
        l = Lazy2.range(1, 10)
        @test l[1] == 1
        @test collect(l[1:5]) == collect(1:5)
    end

    @testset "Listables" begin
        @test_throws MethodError sin()
    end

    @static VERSION ≥ v"1.2" && @testset "avoid stackoverflow" begin
        @test (length(takewhile(<(10), Lazy2.range(1))); true)
        @test (length(takewhile(<(100000), Lazy2.range(1))); true)
    end

    @testset "any/all" begin
        let xs = list(true, false, false)
            @test any(identity, xs) == true
            @test any(xs) == true
            @test all(identity, xs) == false
            @test all(xs) == false
        end
        let yy = list(1, 0, 1)
            @test any(Bool, yy) == true
            @test all(Bool, yy) == false
        end
        # Base method--ensures no ambiguity with methods here
        @test all([true true; true true], dims = 1) == [true true]
    end
end
