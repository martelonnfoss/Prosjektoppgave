# Velg pakkemiljøet der ReSDDP og CPLEX er installert
using Pkg
Pkg.activate(joinpath(@__DIR__, "resddp", "examples"))

# Fortell Julia hvor CPLEX er installert på denne Macen
ENV["CPLEX_STUDIO_BINARIES"] =
    "/Users/martefoss/Applications/CPLEX_Studio222/cplex/bin/arm64_osx"

# Last inn pakkene vi bruker
import ReSDDP
import JuMP
import CPLEX
import JLD2

# Finn fireområdedatasettet
datapath = joinpath(@__DIR__, "datasets", "4area") * "/"

# Les inn innstillinger og data
include(joinpath(datapath, "params.jl"))
model = ReSDDP.load(datapath, parameters)
inflow_model = ReSDDP.load_inflow(datapath, model, parameters)

# Velg CPLEX med innstillingene fra ReSDDP-eksempelet
optimizer = JuMP.optimizer_with_attributes(
    CPLEX.Optimizer,
    "CPX_PARAM_SCRIND" => 0,
    "CPX_PARAM_PREIND" => 1,
    "CPX_PARAM_LPMETHOD" => 2
)

# Les inn ferdigberegnede feasibility cuts
feas_spaces = JLD2.load(
    joinpath(datapath, "feas_spaces.jld2")
)["feas_spaces"]

println("ReSDDP er klargjort med fireområdedatasettet og CPLEX.")

# Opprett en mappe for resultatene
resultpath = joinpath(@__DIR__, "resultater", "4area_test")
mkpath(resultpath)

# Klargjør strategi og starttilstand
strategy = ReSDDP.init_strategy(model, parameters)
init_val = ReSDDP.init_system(model, parameters)

# Beregn driftsstrategien
println("Beregner strategi...")
ReSDDP.train!(
    strategy, init_val, model, inflow_model,
    feas_spaces, parameters;
    optimizer = optimizer
)

# Lagre strategien
JLD2.jldsave(
    joinpath(resultpath, "strategy.jld2");
    strategy = strategy
)

# Simuler kraftsystemets drift med den beregnede strategien
println("Starter simulering...")
results_agg = ReSDDP.simulate_aggregated(
    model, inflow_model, parameters,
    strategy, feas_spaces, init_val;
    optimizer = optimizer
)

# Lagre simuleringsresultatene
JLD2.jldsave(
    joinpath(resultpath, "results_agg.jld2");
    results_agg = results_agg
)

println("Kjøringen er ferdig. Resultatene ligger i: ", resultpath)