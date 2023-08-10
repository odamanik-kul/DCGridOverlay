# Script to analyse the results for the simulated timesteps in the DC grid overlay project
using JSON

##########################################################################
# Read time series file
res_filename = "./test_cases/DC_overlay_grid_RES_1_8760.json"
res = JSON.parsefile(res_filename)

load_filename = "./test_cases/DC_overlay_grid_Demand_1_8760.json"
load = JSON.parsefile(load_filename)

# Read test case file
grid_filename = "./test_cases/DC_overlay_grid.json"
grid = JSON.parsefile(grid_filename)

# Adding name to the branches
for (br_id,br) in grid["branch"]
    br["name"] = "AC_L_$(br["f_bus"])$(br["t_bus"])"
end
for (br_id,br) in grid["branchdc"]
    br["name"] = "DC_L_$(br["fbusdc"])$(br["tbusdc"])"
end


# Read results file
output_filename = "./results/OPF_results_selected_timesteps_ACPPowerModel8760_timesteps.json"
results_raw = JSON.parsefile(output_filename)
##########################################################################

#2723 -> MIN onshore wind
#6311 -> MIN RES
#6541 -> MIN Load/RES
#476  -> MAX Load/RES
#2511 -> MIN offshore wind
#1125 -> MAX demand

obj = [results[i]["objective"] for i in eachindex(results)]


# Max load/RES -> RUN AC OPF
ac_branch_flow = [[results["476"]["solution"]["branch"][i]["pt"],grid["branch"][i]["name"]] for i in eachindex(results["476"]["solution"]["branch"])]
dc_branch_flow = [[results["476"]["solution"]["branchdc"][i]["pt"],grid["branchdc"][i]["name"]] for i in eachindex(results["476"]["solution"]["branchdc"])]
gen = [[results["476"]["solution"]["gen"][i]["pg"],grid["gen"][i]["name"]] for i in eachindex(results["476"]["solution"]["gen"]) if results["476"]["solution"]["gen"][i]["pg"] != 0.0]
load_timestep = [[load[i][476],i] for i in eachindex(load)]
total_load_timestep = sum(load_timestep[i][1] for i in 1:length(load_timestep))

# Min Load/RES
ac_branch_flow = [[results["6541"]["solution"]["branch"][i]["pt"],grid["branch"][i]["name"]] for i in eachindex(results["6541"]["solution"]["branch"])]
dc_branch_flow = [[results["6541"]["solution"]["branchdc"][i]["pt"],grid["branchdc"][i]["name"]] for i in eachindex(results["6541"]["solution"]["branchdc"])]
gen = [[results["6541"]["solution"]["gen"][i]["pg"],grid["gen"][i]["name"]] for i in eachindex(results["6541"]["solution"]["gen"]) if results["6541"]["solution"]["gen"][i]["pg"] != 0.0]
load_timestep = [[load[i][6541],i] for i in eachindex(load)]
total_load_timestep = sum(load_timestep[i][1] for i in 1:length(load_timestep))



time_steps = sort([t for (t,sim) in results_raw])
max_time_steps = 8760
n_time_steps = length(time_steps)
# results_sorted = [results_raw[string(i)] for i=1:n_time_steps]
results_sorted = [merge(results_raw[string(i)],Dict("time_step" => string(i))) for i=1:max_time_steps if haskey(results_raw,string(i))]

conv_ids = [conv_id for (conv_id,conv) in grid["convdc"]] # dict order
conv_ids = [string(i) for i=1:length(grid["convdc"])] # ascend
# results["convdc"] = Dict(conv_id => Dict("vmconv" => [],"vaconv" => [],"pconv" => [],"pdc" => [],"pgrid" => [],"qgrid" => []) for conv_id in conv_ids)
results["convdc"] = Dict(conv_id => Dict("vaconv" => [],"pconv" => [],"pdc" => [],"pgrid" => []) for conv_id in conv_ids)
for i=1:n_time_steps
    for conv_id in conv_ids
        for (sol_id,sol) in results["convdc"][conv_id]
            push!(sol,results_sorted[i]["solution"]["convdc"][conv_id][sol_id])
        end
    end
end
results_sorted[1]["solution"]["convdc"]["4"]
results["convdc"]["4"]

# busdc_ids = [busdc_id for (busdc_id,busdc) in grid["busdc"]] # dict order
# busdc_ids = [string(i) for i=1:length(grid["busdc"])] # ascend
# results["busdc"] = Dict(busdc_id => Dict("vm" => []) for busdc_id in busdc_ids)
# for i=1:n_time_steps    
#     for busdc_id in busdc_ids
#         for (sol_id,sol) in results["busdc"][busdc_id]
#             push!(sol,results_sorted[i]["solution"]["busdc"][busdc_id][sol_id])
#         end
#     end
# end
# results_sorted[1]["solution"]["busdc"]["4"]
# results["busdc"]["4"]

branchdc_ids = [branchdc_id for (branchdc_id,branchdc) in grid["branchdc"]] # dict order
branchdc_ids = [string(i) for i=1:length(grid["branchdc"])] # ascend
results["branchdc"] = Dict(branchdc_id => Dict("pt" => [],"pf" => [],"pabs" => []) for branchdc_id in branchdc_ids)
for i=1:n_time_steps    
    for branchdc_id in branchdc_ids
        for (sol_id,sol) in results["branchdc"][branchdc_id]
            if sol_id == "pabs"
                pabs_max = maximum([results_sorted[i]["solution"]["branchdc"][branchdc_id]["pf"],results_sorted[i]["solution"]["branchdc"][branchdc_id]["pt"]])
                push!(sol,pabs_max)
            else
                push!(sol,results_sorted[i]["solution"]["branchdc"][branchdc_id][sol_id])
            end
        end
    end
end
results_sorted[1]["solution"]["branchdc"]["4"]
results["branchdc"]["4"]

branch_ids = [branch_id for (branch_id,branch) in grid["branch"]] # dict order
branch_ids = [string(i) for i=1:length(grid["branch"])] # ascend
results["branch"] = Dict(branch_id => Dict("pt" => [],"pf" => [],"pabs" => []) for branch_id in branch_ids)
for i=1:n_time_steps    
    for branch_id in branch_ids
        for (sol_id,sol) in results["branch"][branch_id]
            if sol_id == "pabs"
                pabs_max = maximum([results_sorted[i]["solution"]["branch"][branch_id]["pf"],results_sorted[i]["solution"]["branch"][branch_id]["pt"]])
                push!(sol,pabs_max)
            else
                push!(sol,results_sorted[i]["solution"]["branch"][branch_id][sol_id])
            end
        end
    end
end

using Plots

# plot_conv_vmconv = scatter(1:n_time_steps,results["convdc"]["4"]["vmconv"],ylims=(0.85,1.05), legend=false)
plot_busdc_vm = scatter(1:n_time_steps,results["busdc"]["5"]["vm"],ylims=(0.85,1.05), legend=false)
# plot_branchdc_pabs = scatter(1:n_time_steps,results["branchdc"]["9"]["pabs"],ylims=(0,200), legend=false)
plot_branchdc_pf = scatter(1:n_time_steps,results["branchdc"]["1"]["pf"], legend=false, alpha=0.6,markerstrokewidth=0)

plot_branch_pabs = scatter(1:n_time_steps,results["branch"]["8"]["pabs"],ylims=(0,200), legend=false)

for bd in branchdc_ids
    plot_branchdc_pf = scatter(1:n_time_steps,results["branchdc"]["1"]["pf"], legend=false, alpha=0.6,markerstrokewidth=0,ylims=(-200,200))
    title!(bd)
    Plots.svg(joinpath("./","branchdc_flow_-$bd.svg"))
end
for b in branch_ids
    plot_branch_pf = scatter(1:n_time_steps,results["branch"]["1"]["pf"], legend=false, alpha=0.6,markerstrokewidth=0,ylims=(-200,200))
    title!(b)
    Plots.svg(joinpath("./","branch_flow_-$b.svg"))
end
joinpath("../","branch_flow_-.svg")
plot_conv_pgrid = scatter(1:n_time_steps,results["convdc"]["4"]["pgrid"])