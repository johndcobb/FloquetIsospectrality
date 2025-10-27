# Main file for lambdagens6, chunk metadata and helpers.
# Generated from lambdagens6.m2

const lambdagens6_CHUNK_FILES = [
    "lambdagens6_chunk_1.jl",
]

function lambdagens6_chunk_count()
    return length(lambdagens6_CHUNK_FILES)
end

function lambdagens6_load_chunk(i::Integer)
    @assert 1 <= i <= lambdagens6_chunk_count()
    chunk_file = lambdagens6_CHUNK_FILES[i]
    return include(joinpath(@__DIR__, chunk_file))
end

function lambdagens6_each_chunk(f::Function)
    for cf in lambdagens6_CHUNK_FILES
        data = include(joinpath(@__DIR__, cf))
        f(data)
        GC.gc()
    end
end

function lambdagens6_get_all_entries()
    all = []
    for i in 1:lambdagens6_chunk_count()
        append!(all, lambdagens6_load_chunk(i))
    end
    return all
end

# Usage: include(joinpath(@__DIR__, "lambdagens6.jl"))
# Then either call lambdagens6_load_chunk(i) to load chunk i,
# use lambdagens6_each_chunk(f) to process chunks one-by-one, or
# call lambdagens6_get_all_entries() to concatenate all chunks into memory.
