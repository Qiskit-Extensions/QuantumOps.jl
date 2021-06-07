# # Jordan-Wigner transform

# Load the interface to electronic structure packages.
# As with Qiskit and OpenFermion driver libraries, `ElectronicStructure` does
# a bit of calculation, as well.
using ElectronicStructure

# Load `QuantumOps`, the implementation of Pauli and Fermionc operators
using QuantumOps

# `ElectronicStructure` has no hard dependency on pyscf.
# But, using `PyCall` will trigger loading pyscf-specific code in `ElectronicStructure`
using PyCall

# Load some specific identifiers
using ElectronicStructure: one_electron_integrals, MolecularData, PySCF

# ## Specify geometry of molecules

# Define geometries for three molecules: specification of atoms and their positions.
# These are molecular hydrogen, `LiH`, and water.
geoms = (
    Geometry(Atom(:H, (0., 0., 0.)), Atom(:H, (0., 0., 0.7414))),

    Geometry(Atom(:Li, (0., 0., 0.)), Atom(:H, (0., 0., 1.4))),

    Geometry(Atom(:O, (0., 0., 0.)), Atom(:H, (0.757, 0.586, 0.)),
             Atom(:H, (-0.757, 0.586, 0.)))
);

# Choose one of the geometries, 1, 2, or 3.
geom = geoms[1]

# Choose a orbital basis set.
basis = "sto-3g";
## basis = "631g"

# We have chosen the crudest basis set and the smallest molecule. Otherwise
# the size of the data structures is too large to display in a demonstration.

# ## Compute interaction integrals for the chosen molecule and basis set

# Construct the specification of the electronic structure problem.
mol_spec = MolecularSpec(geometry=geom, basis=basis)

# Do calculations using `PySCF` and populate a `MolecularData` object with results.
# `mol_pyscf` holds a constant, a rank-two tensor, and a rank-four tensor.
mol_pyscf = MolecularData(PySCF, mol_spec);

# ## Include spin orbitals and change the representation

# Create an interaction operator from one- and two-body integrals and a constant.
# This does just a bit of manipulation of `mol_data`; converting space orbitals
# into space-and-spin orbitals. There are options for choosing chemists' or physicists'
# index ordering and block- or inteleaved-spin orbital ordering.
# We take the default here,
# which gives the same as the operator by the same name in OpenFermion.
# The data is still in the form of rank two and four tensors, but the size of each
# dimension is doubled.
iop = InteractionOperator(mol_pyscf);

# Now we convert `iop` to a more-sparse format; a `FermiSum` (alias for `OpSum{FermiOp}`).
# This is sparse in the sense that only non-zero entries in the tensors in `iop` are represented.
# However, it is not as sparse as it could be, in that identity operators on modes are represented
# explicitly.
fermi_op = FermiSum(iop)

# We won't use it now, but let's look at a sparser representation, backed by a `SparseVector`.
# Here, only non-identity operators are represented explicitly.
using QuantumOps: sparse_op
sparse_op(fermi_op)

# ## Jordan-Wigner transform

using QuantumOps: jordan_wigner

# Compute the Jordan-Wigner transform
jordan_wigner(fermi_op)

# You can also perform the transform on a single term (`OpTerm`). This always returns
# a sum (`OpSum{<:AbstractPauli}`).
# Here is a single term.
fermi_op[2]
# The transform is
jordan_wigner(fermi_op[2])

# An optional second argument of type `<:AbstractPauli` determines the output type.
# The default `AbstractPauli` for all of `QuantumOps` is
QuantumOps.PauliDefault
# Here, we choose `PauliI` instead
jordan_wigner(fermi_op, PauliI)

# We have mentioned before that the performance of `PauliI` vs. `Pauli` may vary greatly
# in general. But, in most cases, overall performance does not hinge on choosing beteen the two.
