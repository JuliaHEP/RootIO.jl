push!(LOAD_PATH,"../src/")
using Documenter, RootIO

makedocs(
    sitename = "RootIO.jl",
    modules = [RootIO],
    checkdocs = :exports
)

deploydocs(
    repo = "github.com/JuliaHEP/RootIO.jl",
    push_preview = true
)