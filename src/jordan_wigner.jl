## Jordan-Wigner helper
function fill_pauli(pad, op_ind, fill_op, end_op)
    str = Vector{Paulis.Pauli}(undef, pad)
    if pad <  op_ind
        throw(DimensionMismatch("pad is less than op_ind."))
    end
    @inbounds for i in 1:op_ind-1
        str[i] = fill_op
    end
    str[op_ind] = end_op
    @inbounds for i in op_ind+1:pad
        str[i] = Paulis.I
    end
    return str
end

## Jordan-Wigner
function jordan_wigner(op::FermiOp, op_ind::Integer, pad::Integer)
    if op === lower_op
        strx = fill_pauli(pad, op_ind, Paulis.Z, Paulis.X)
        stry = fill_pauli(pad, op_ind, Paulis.Z, Paulis.Y)
        coeffs = [-1/2, -im/2]
    elseif op === raise_op
        strx = fill_pauli(pad, op_ind, Paulis.Z, Paulis.X)
        stry = fill_pauli(pad, op_ind, Paulis.Z, Paulis.Y)
        coeffs = [-1/2, im/2]
    elseif op === number_op
        strx = fill(Paulis.I, pad)
        stry = fill_pauli(pad, op_ind, Paulis.I, Paulis.Z)
        coeffs = complex.([1/2, -1/2])
    elseif op === empty_op
        strx = fill(Paulis.I, pad)
        stry = fill_pauli(pad, op_ind, Paulis.I, Paulis.Z)
        coeffs = complex.([1/2, 1/2])
    else
        raise(DomainError(op))
    end
    return OpSum{Pauli}([strx, stry], coeffs; already_sorted=true)
end

function jordan_wigner(term::FermiTerm)
    pad = length(term)
    facs = []
    for (i, op) in enumerate(term)
        if op !== I_op #  op === raise_op || op === lower_op || op === number_op || op === empty_op
            push!(facs, jordan_wigner(op, i, pad))
        end
    end
    if isempty(facs)  # String is all I_op
        return(OpSum{Pauli}([fill(one(Pauli), length(term))], [complex(term.coeff)]))
    end
    return term.coeff * reduce(*, facs) # TODO: performance
end

function jordan_wigner(fsum::FermiSum)
    psum = jordan_wigner(fsum[1]) # could use already sorted flag
    for i in 2:length(fsum)
        append!(psum, jordan_wigner(fsum[i]))
    end
    return sort_and_sum_duplicates!(psum)
end

####
#### Jordan-Wigner using Fermi operators augmented by Z = N - E
####

## These are experimental, and so far do not seem very useful

function fill_fermi(pad, op_ind, fill_op, end_op)
    str = Vector{FermiOps.FermiOp}(undef, pad)
    if pad <  op_ind
        throw(DimensionMismatch("pad is less than op_ind."))
    end
    @inbounds for i in 1:op_ind-1
        str[i] = fill_op
    end
    str[op_ind] = end_op
    @inbounds for i in op_ind+1:pad
        str[i] = FermiOps.I_op
    end
    return str
end

## Jordan-Wigner
function jordan_wigner_fermi(op::FermiOp, op_ind::Integer, pad::Integer)
    if op === lower_op
        str = fill_fermi(pad, op_ind, FermiOps.Z_op, FermiOps.lower_op)
        return FermiTerm(str, complex(1.0))
    elseif op === raise_op
        str = fill_fermi(pad, op_ind, FermiOps.Z_op, FermiOps.raise_op)
        return FermiTerm(str, complex(1.0))
    elseif op === number_op
        str = fill_fermi(pad, op_ind, FermiOps.I_op, FermiOps.number_op)
        return FermiTerm(str, complex(1.0))
    elseif op === empty_op
        str = fill_fermi(pad, op_ind, FermiOps.I_op, FermiOps.empty_op)
        return FermiTerm(str, complex(1.0))
    elseif op === I_op
        str = fill(FermiOps.I_op, pad)
        return FermiTerm(str, complex(1.0))
    else
        raise(DomainError(op))
    end
end

function jordan_wigner_fermi(term::FermiTerm)
    pad = length(term)
    facs = [] # FermiTerm{FermiOp, Vector{FermiOp}, ComplexF64}[]
    for (i, op) in enumerate(term)
        if op === raise_op || op === lower_op || op === number_op
            push!(facs, jordan_wigner_fermi(op, i, pad))
        end
    end
    if isempty(facs)
        return (1.0 + 0.0im) * term
    end
    return term.coeff * reduce(*, facs)  # TODO: performance
end

function jordan_wigner_fermi(fsum::FermiSum)
#    ofsum = jordan_wigner_fermi(fsum[1])
    terms = FermiTerm{FermiOp, Vector{FermiOp}, ComplexF64}[]
    for i in 1:length(fsum)
#        println(i)
        push!(terms, jordan_wigner_fermi(fsum[i]))
    end
    nterms = [x for x in terms]
    # println(typeof(nterms))
    # return nterms
    return FermiSum(terms)
end
