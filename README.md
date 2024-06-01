# OceanFlavoredFluids

Tutorials and scripts that teach ocean-flavored fluid dynamics with [Oceananigans](https://github.com/CliMA/Oceananigans.jl).
Oceananigans is Julia software for simulating the dynamics of incompressible fluids, with a focus on ocean applications.

## Why learn fluid dynamics with Oceananigans?

Oceananigans has an innovative user interface.
Unlike in many other modeling systems for computational fluid dynamics or oceanography, where users write config files or namelists, Oceananigans users write programs ("scripts") that implement their numerical experiments.
This might sounds scary, but its actually easy --- using Oceananigans is like using a plotting library, or a library for data analysis.
The benefits of this paradigm are huge: user scripts and the science they do can be logical, concise, interpretable, and pedagogical.
And creative science is possible, because functions for forcing, boundary conditions, and background states injected directly into hot inner loops and arbitrary code can be executed between time-steps to update auxiliary model data or alter model behavior.

