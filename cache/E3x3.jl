# Main file for E3x3, chunk metadata and helpers.
# Generated from E3x3.m2

const E3x3_CHUNK_FILES = [
    "E3x3_chunk_1.jl",
    "E3x3_chunk_2.jl",
    "E3x3_chunk_3.jl",
]

function E3x3_chunk_count()
    return length(E3x3_CHUNK_FILES)
end

function E3x3_load_chunk(i::Integer)
    @assert 1 <= i <= E3x3_chunk_count()
    chunk_file = E3x3_CHUNK_FILES[i]
    return include(joinpath(@__DIR__, chunk_file))
end

function E3x3_each_chunk(f::Function)
    for cf in E3x3_CHUNK_FILES
        data = include(joinpath(@__DIR__, cf))
        f(data)
        GC.gc()
    end
end

function E3x3_get_all_entries()
    all = []
    for i in 1:E3x3_chunk_count()
        append!(all, E3x3_load_chunk(i))
    end
    return all
end

# Usage: include(joinpath(@__DIR__, "E3x3.jl"))
# Then either call E3x3_load_chunk(i) to load chunk i,
# use E3x3_each_chunk(f) to process chunks one-by-one, or
# call E3x3_get_all_entries() to concatenate all chunks into memory.
