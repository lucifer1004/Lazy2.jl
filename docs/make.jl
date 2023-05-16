using Lazy2
using Documenter

DocMeta.setdocmeta!(Lazy2, :DocTestSetup, :(using Lazy2); recursive = true)

makedocs(;
         modules = [Lazy2],
         authors = "Gabriel Wu <wuzihua@pku.edu.cn> and contributors",
         repo = "https://github.com/lucifer1004/Lazy2.jl/blob/{commit}{path}#{line}",
         sitename = "Lazy2.jl",
         format = Documenter.HTML(;
                                  prettyurls = get(ENV, "CI", "false") == "true",
                                  canonical = "https://lucifer1004.github.io/Lazy2.jl",
                                  edit_link = "main",
                                  assets = String[]),
         pages = [
             "Home" => "index.md",
         ])

deploydocs(;
           repo = "github.com/lucifer1004/Lazy2.jl",
           devbranch = "main")
