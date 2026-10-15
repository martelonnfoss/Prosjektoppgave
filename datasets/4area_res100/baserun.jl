using Revise # Sikrer at oppdateringer av kildekode kompileres automatisk
using Pkg
Pkg.activate(@__DIR__) # Aktiverer lokalt pakkemiljø
# Pkg.resolve()
Pkg.instantiate()

using ReSDDP
using Random
include("params.jl") # Import parameters

import JuMP
import CPLEX

optimizer = JuMP.optimizer_with_attributes( CPLEX.Optimizer, "CPX_PARAM_SCRIND" => 0, "CPX_PARAM_PREIND" => 1, "CPX_PARAM_LPMETHOD" => 2 )

println("Threads available: ",Threads.nthreads())

datapath = "C:\\Users\\<UserName>\\data\\res100\\4area_res100\\"

##OPTIONS############
LFeasibilityBuild = true
LFeasibility = true
LStrategyNew = true
LStrategyContinue = false
LOnlySim = false
#Random.seed!(3)
#####################

LStrategy = LStrategyNew || LStrategyContinue

if LOnlySim
    LStrategy = LStrategyNew = LStrategyContinue = false
end

model = ReSDDP.load(datapath, parameters)

inflow_model = load_inflow(datapath, model, parameters)

using JLD2 
using FileIO 

##FEASIBILITY
file = File(format"JLD2", joinpath(@__DIR__, "feas_spaces.jld2"))
if LFeasibilityBuild
    println("Compute feasibility cuts..")
    feas_spaces = feasibility(model, inflow_model, parameters, datapath; optimizer=optimizer)
    save(file, "feas_spaces", feas_spaces)
    print_feas(datapath,feas_spaces[1],model.NHSys)
end
data = JLD2.load(file) 
feas_spaces = data["feas_spaces"]

ReSDDP.print(model, parameters, LFeasibility, LStrategy)
init_val = init_system(model, parameters)

##STRATEGY
file = File(format"JLD2", joinpath(@__DIR__, "strategy.jld2"))
if LStrategyContinue
    println("Continue strategy computation..")
    data = JLD2.load(file) 
    oldstrategy = data["strategy"]
    newstrategy = extend_strategy(model, parameters, oldstrategy)
    train!(newstrategy, init_val, model, inflow_model, feas_spaces, parameters; optimizer=optimizer)
    newfile = File(format"JLD2", joinpath(@__DIR__, "strategy_new.jld2"))
    save(newfile, "strategy", newstrategy)
    data = JLD2.load(newfile) 
    strategy = data["strategy"]
end

if LStrategyNew
    println("Start new strategy computation..")
    strategy = init_strategy(model, parameters)
    train!(strategy, init_val, model, inflow_model, feas_spaces, parameters; optimizer=optimizer)
    save(file, "strategy", strategy)
    data = JLD2.load(file) 
    strategy = data["strategy"]
end

if LStrategyContinue
    mv("strategy.jld2","strategy_old.jld2",force=true)
    mv("strategy_new.jld2","strategy.jld2",force=true)
end

if LOnlySim
    data = JLD2.load(file) 
    strategy = data["strategy"]
end

##SIMULATION
println("Start simulation ..")
results_agg = simulate_aggregated(model, inflow_model, parameters, strategy, feas_spaces, init_val, optimizer=optimizer)

# Print results to ASCII files 
println("Write results ..")
print_results(datapath,results_agg,model.NArea,model.NHSys,parameters.Control.NScenSim,parameters.Control.NStageSim,parameters.Time.NK,model.NLine,parameters.Time)
print_dims(datapath,model.NHSys,parameters.Control.NStage,parameters.Control.NScen,strategy.NCut,parameters.Control.MaxIter,parameters.Control.CCMaxIter)
print_strategy(datapath,strategy,parameters.Control.LCostApprox)

