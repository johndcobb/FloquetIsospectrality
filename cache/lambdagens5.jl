# Main file for lambdagens5, chunk metadata and helpers.
# Generated from lambdagens5.m2

const lambdagens5_CHUNK_FILES = [
    "lambdagens5_chunk_1.jl",
]

function lambdagens5_chunk_count()
    return length(lambdagens5_CHUNK_FILES)
end

function lambdagens5_load_chunk(i::Integer)
    @assert 1 <= i <= lambdagens5_chunk_count()
    chunk_file = lambdagens5_CHUNK_FILES[i]
    return include(joinpath(@__DIR__, chunk_file))
end

function lambdagens5_each_chunk(f::Function)
    for cf in lambdagens5_CHUNK_FILES
        data = include(joinpath(@__DIR__, cf))
        f(data)
        GC.gc()
    end
end

function lambdagens5_get_all_entries()
    all = []
    for i in 1:lambdagens5_chunk_count()
        append!(all, lambdagens5_load_chunk(i))
    end
    return all
end

# Usage: include(joinpath(@__DIR__, "lambdagens5.jl"))
# Then either call lambdagens5_load_chunk(i) to load chunk i,
# use lambdagens5_each_chunk(f) to process chunks one-by-one, or
# call lambdagens5_get_all_entries() to concatenate all chunks into memory.
