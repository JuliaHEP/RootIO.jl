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

function _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, _branch_types, _branch_names)
    _tree = ROOT.TTree(name, title)
    _curr_branch_array = []
    for i in 1:length(_branch_types)
        if _branch_types[i] <: CxxWrap.StdVector
            _ptr = (_branch_types[i])()
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), _ptr, 100, 99)
            push!(_curr_branch_array, _curr_branch)
        else
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), Ref(one(_branch_types[i])), 100, 99)
            push!(_curr_branch_array, _curr_branch)
        end
    end
    return TTree(_tree, _curr_branch_array, file)
end

function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)

    println("Creating a new TTree")

    _branch_types_array = []
    _branch_names_array = []
    if isa(data, DataType)
        _branch_types_array = fieldtypes(data)
        _branch_names_array = fieldnames(data)
    else
        _branch_types_array = fieldtypes(typeof(data))
        _branch_names_array = fieldnames(typeof(data))
    end

    it = _makeTTree(file, name, title, _branch_types_array, _branch_names_array)

    if !isa(data, DataType)
        Fill(it, data)
    end

    return it
end

function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; kwargs...)
    println("Creating a new TTree")

    _branch_types_array = []
    _branch_names_array = NTuple{length(kwargs), Symbol}(collect(keys(kwargs)))

    if isa(kwargs[1], DataType)
        _branch_types_array = NTuple{length(kwargs), DataType}(collect(values(kwargs)))
    else
        _branch_types_array = NTuple{length(kwargs), DataType}([eltype(value) for value in values(kwargs)])
    end

    it = _makeTTree(file, name, title, _branch_types_array, _branch_names_array)

    if !isa(kwargs[1], DataType)
        num_rows = length(kwargs[1])
        for curr_row in 1:num_rows
            for curr_branch in 1:length(kwargs)
                if typeof(kwargs[curr_branch][curr_row]) <: CxxWrap.StdVector
                    ROOT.SetObject(it._branch_array[curr_branch], kwargs[curr_branch][curr_row])
                else
                    x = kwargs[curr_branch][curr_row]
                    ROOT.SetAddress(it._branch_array[curr_branch], Ref(x))
                end
            end
            _preserved_vars = it._branch_array
            GC.@preserve _preserved_vars ROOT.Fill(it._ROOT_ttree)
        end
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
