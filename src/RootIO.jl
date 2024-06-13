module RootIO

import ROOT, Tables, CxxWrap

struct TTree
    _ROOT_ttree::ROOT.TTree
    _branch_array
    _file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}
end

function Write(tree::TTree)
    ROOT.Write(tree._ROOT_ttree)
end

function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)

    println("Creating a new TTree")

    _tree = ROOT.TTree(name, title)

    _branch_types_array = []
    _branch_names_array = []
    if isa(data, DataType)
        _branch_types_array = fieldtypes(data)
        _branch_names_array = fieldnames(data)
    else
        _branch_types_array = fieldtypes(typeof(data))
        _branch_names_array = fieldnames(typeof(data))
    end
    _curr_branch_array = []

    for i in 1:fieldcount(data)
        if _branch_types_array[i] <: CxxWrap.StdVector
            _ptr = (_branch_types_array[i])()
            _curr_branch = ROOT.Branch(_tree, string(_branch_names_array[i]), _ptr, 100, 99)
            push!(_curr_branch_array, _curr_branch)
        else
            _curr_branch = ROOT.Branch(_tree, string(_branch_names_array[i]), Ref(one(_branch_types_array[i])), 100, 99)
            push!(_curr_branch_array, _curr_branch)
        end
    end

    it = TTree(_tree, _curr_branch_array, file)

    if !isa(data, DataType)
        Fill(it, data)
    end

    return it
end

function Fill(tree::TTree, data)
    if Tables.istable(data)
        println("Filling the TTree with a table")
        for row in Tables.rows(data)
            Fill(tree, row)
        end
    else
        println("Filling the TTtree with a row")
        row = map(field -> getfield(data, field), fieldnames(typeof(data)))
        for i in 1:length(tree._branch_array)
            if typeof(row[i]) <: CxxWrap.StdVector
                ROOT.SetObject(tree._branch_array[i], row[i])
            else
                ROOT.SetAddress(tree._branch_array[i], Ref(row[i]))
            end
        end
        _preserved_vars = tree._branch_array
        GC.@preserve _preserved_vars ROOT.Fill(tree._ROOT_ttree)
    end
end 

end # module RootIO
