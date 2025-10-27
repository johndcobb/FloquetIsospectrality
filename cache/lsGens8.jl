# Main file for lsGens8, chunk metadata and helpers.
# Generated from lsGens8.m2

const lsGens8_CHUNK_FILES = [
    "lsGens8_chunk_1.jl",
]

function lsGens8_chunk_count()
    return length(lsGens8_CHUNK_FILES)
end

function lsGens8_load_chunk(i::Integer)
    @assert 1 <= i <= lsGens8_chunk_count()
    chunk_file = lsGens8_CHUNK_FILES[i]
    return include(joinpath(@__DIR__, chunk_file))
end

function lsGens8_each_chunk(f::Function)
    for cf in lsGens8_CHUNK_FILES
        data = include(joinpath(@__DIR__, cf))
        f(data)
        GC.gc()
    end
end

function lsGens8_get_all_entries()
    all = []
    for i in 1:lsGens8_chunk_count()
        append!(all, lsGens8_load_chunk(i))
    end
    return all
end

# Usage: include(joinpath(@__DIR__, "lsGens8.jl"))
# Then either call lsGens8_load_chunk(i) to load chunk i,
# use lsGens8_each_chunk(f) to process chunks one-by-one, or
# call lsGens8_get_all_entries() to concatenate all chunks into memory.
