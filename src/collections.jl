# TODO: Implement liblazy functions over standard arrays / other collections

function Base.split(xs::Vector{T}, x; keep = true) where {T}
    result = Vector{T}[]
    push!(result, T[])
    for i in 1:length(xs)
        if xs[i] == x
            (keep || !(isempty(result[end]) || i == length(xs))) &&
                push!(result, T[])
        else
            push!(result[end], xs[i])
        end
    end
    isempty(result[end]) && pop!(result)
    return result
end

export frequencies

function frequencies(xs)
    freqs = Dict{eltype(xs), Int}()
    for x in xs
        freqs[x] = get(freqs, x, 0) + 1
    end
    return freqs
end

export init

init(xs) = xs[1:(end - 1)]

# function Base.getindex{K, V}(d::Dict{K, V}, ks::Vector{K})
#   vs = similar(ks, V, 0)
#   for k in ks
#     push!(vs, d[k])
#   end
#   return vs
# end

for f in (:takewhile, :splitby, :takeuntil)
    @eval $(f)(f::Function, xs) = $(f)(f, seq(xs))
end

function groupby(f, xs)
    result = d()
    for x in xs
        push!(get!(() -> [], result, f(x)), x)
    end
    return result
end
