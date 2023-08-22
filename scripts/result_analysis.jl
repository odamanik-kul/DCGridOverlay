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

case_name = "dcopf" # or "acopf" or any name to create a folder
# Read results file
# Choose result file (.json file)
output_filename = "./results/external/OPF_results_selected_timesteps_DCPPowerModel_8760_timesteps.json"
results_raw = JSON.parsefile(output_filename)
time_steps = sort([t for (t,sim) in results_raw])
max_time_steps = 8760
n_time_steps = length(time_steps)
# results_sorted = [results_raw[string(i)] for i=1:n_time_steps]
results_sorted = [merge(results_raw[string(i)],Dict("time_step" => string(i))) for i=1:max_time_steps if haskey(results_raw,string(i))]

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

# DC branch flow
branchdc_ids = [branchdc_id for (branchdc_id,branchdc) in grid["branchdc"]] # dict order
branchdc_ids = [string(i) for i=1:length(grid["branchdc"])] # ascend
results["branchdc"] = Dict(branchdc_id => Dict("pt" => [],"pf" => [],"pabs" => []) for branchdc_id in branchdc_ids)
for i=1:n_time_steps    
    for branchdc_id in branchdc_ids
        branch_pmax = grid["branchdc"][branchdc_id]["rateA"]
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
# DC branch flow - Normalized
branchdc_ids = [branchdc_id for (branchdc_id,branchdc) in grid["branchdc"]] # dict order
branchdc_ids = [string(i) for i=1:length(grid["branchdc"])] # ascend
results["branchdc_norm"] = Dict(branchdc_id => Dict("pt" => [],"pf" => [],"pabs" => []) for branchdc_id in branchdc_ids)
for i=1:n_time_steps    
    for branchdc_id in branchdc_ids
        branch_pmax = grid["branchdc"][branchdc_id]["rateA"]
        for (sol_id,sol) in results["branchdc_norm"][branchdc_id]
            if sol_id == "pabs"
                pabs_max = maximum([results_sorted[i]["solution"]["branchdc"][branchdc_id]["pf"],results_sorted[i]["solution"]["branchdc"][branchdc_id]["pt"]])/branch_pmax
                push!(sol,pabs_max)
            else
                push!(sol,results_sorted[i]["solution"]["branchdc"][branchdc_id][sol_id]/branch_pmax)
            end
        end
    end
end
# AC branch flow
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
# AC branch flow - Normalized
branch_ids = [branch_id for (branch_id,branch) in grid["branch"]] # dict order
branch_ids = [string(i) for i=1:length(grid["branch"])] # ascend
results["branch_norm"] = Dict(branch_id => Dict("pt" => [],"pf" => [],"pabs" => []) for branch_id in branch_ids)
for i=1:n_time_steps    
    for branch_id in branch_ids
        branch_pmax = grid["branch"][branch_id]["rate_a"]
        for (sol_id,sol) in results["branch"][branch_id]
            if sol_id == "pabs"
                pabs_max = maximum([results_sorted[i]["solution"]["branch"][branch_id]["pf"],results_sorted[i]["solution"]["branch"][branch_id]["pt"]])/branch_pmax
                push!(sol,pabs_max)
            else
                push!(sol,results_sorted[i]["solution"]["branch"][branch_id][sol_id]/branch_pmax)
            end
        end
    end
end




