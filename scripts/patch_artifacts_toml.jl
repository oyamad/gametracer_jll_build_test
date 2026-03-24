using TOML

function main(path::String, local_uri::String)
    data = TOML.parsefile(path)

    entries = get(data, "gametracer", nothing)
    entries isa Vector || error("Expected [[gametracer]] entries in $path")

    idx = findfirst(entries) do entry
        get(entry, "arch", nothing) == "x86_64" &&
        get(entry, "os", nothing) == "windows"
    end

    idx === nothing && error("Did not find x86_64/windows artifact entry in Artifacts.toml")

    downloads = get(entries[idx], "download", nothing)
    downloads isa Vector || error("Selected artifact entry has no [[download]] section")

    for dl in downloads
        dl["url"] = local_uri
    end

    open(path, "w") do io
        TOML.print(io, data)
    end
end

length(ARGS) == 2 || error("usage: julia patch_artifacts_toml.jl <Artifacts.toml> <file:///...tar.gz>")
main(ARGS[1], ARGS[2])
