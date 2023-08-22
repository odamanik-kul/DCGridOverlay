# Script to run the OPF simulations for the DC Grid overlay project using CbaOPF
using PowerModels; const _PM = PowerModels
using PowerModelsACDC; const _PMACDC = PowerModelsACDC
using JSON
using JuMP
using Ipopt, Gurobi

##########################################################################
# Call and parse the grid, RES and load time series 
##########################################################################
conv_power = 8.0
test_case_file = "DC_overlay_grid_$(conv_power)_GW_convdc.json"
test_case = _PM.parse_file("./test_cases/$test_case_file")
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
start_hour = 1
number_of_hours = 8760

RES_time_series_file = "DC_overlay_grid_RES_$(start_hour)_$(number_of_hours).json"
RES_time_series = JSON.parsefile("./test_cases/$RES_time_series_file")

load_time_series_file = "DC_overlay_grid_Demand_$(start_hour)_$(number_of_hours).json"
load_time_series = JSON.parsefile("./test_cases/$load_time_series_file")

##########################################################################
# Define solvers
##########################################################################
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6)
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer)

##########################################################################
# Creating dictionaries for RES and load time series
##########################################################################
selected_timesteps_RES_time_series = Dict{String,Any}()
selected_timesteps_load_time_series = Dict{String,Any}()
result_timesteps = Dict{String,Any}()
#timesteps = ["476", "6541", "2511", "2723","6311", "1125"]
timesteps = collect(1:8760)
for l in timesteps
    if typeof(l) == String 
        selected_timesteps_RES_time_series["$l"] = Dict{String,Any}()
        for i in keys(RES_time_series)
            selected_timesteps_RES_time_series["$l"]["$i"] = Dict{String,Any}()
            selected_timesteps_RES_time_series["$l"]["$i"]["name"] = deepcopy(RES_time_series["$i"]["name"])
            selected_timesteps_RES_time_series["$l"]["$i"]["time_series"] = deepcopy(RES_time_series["$i"]["time_series"][parse(Int64,l)])
        end
    elseif typeof(l) == Int64 
        selected_timesteps_RES_time_series["$l"] = Dict{String,Any}()
        for i in keys(RES_time_series)
            selected_timesteps_RES_time_series["$l"]["$i"] = Dict{String,Any}()
            selected_timesteps_RES_time_series["$l"]["$i"]["name"] = deepcopy(RES_time_series["$i"]["name"])
            selected_timesteps_RES_time_series["$l"]["$i"]["time_series"] = deepcopy(RES_time_series["$i"]["time_series"][l])
        end
    end
end

for l in timesteps
    if typeof(l) == String 
        selected_timesteps_load_time_series["$l"] = Dict{String,Any}()
        for i in keys(load_time_series)
            selected_timesteps_load_time_series["$l"]["$i"] = Dict{String,Any}()
            selected_timesteps_load_time_series["$l"]["$i"]["time_series"] = deepcopy(load_time_series["$i"][parse(Int64,l)])
        end
    elseif typeof(l) == Int64 
        selected_timesteps_load_time_series["$l"] = Dict{String,Any}()
        for i in keys(load_time_series)
            selected_timesteps_load_time_series["$l"]["$i"] = Dict{String,Any}()
            selected_timesteps_load_time_series["$l"]["$i"]["time_series"] = deepcopy(load_time_series["$i"][l])
        end
    end
end


# Defining function, to be cleaned up
function solve_opf_timestep(data,RES,load,timesteps,conv_power;output_filename::String = "/Users/giacomobastianel/Library/CloudStorage/OneDrive-KULeuven/DC_grid_overlay_results/results")
    #function solve_opf_timestep(data,RES,load,timesteps,conv_power;output_filename::String = "./results/OPF_results_selected_timesteps")
    result_timesteps_dc = Dict{String,Any}()
    result_timesteps_ac = Dict{String,Any}()

    for t in timesteps
        test_case_timestep = deepcopy(data)
        for (g_id,g) in test_case_timestep["gen"]
            if g["type"] != "Conventional"
                g["pmax"] = deepcopy(g["pmax"]*RES["$t"][g_id]["time_series"])
                g["qmax"] = deepcopy(g["qmax"]*RES["$t"][g_id]["time_series"]) 
            end
        end
        for (l_id,l) in test_case_timestep["load"]
            l["pd"] = deepcopy(load["$t"]["Bus_"*l_id]["time_series"]*l["cosphi"])
            l["qd"] = deepcopy(load["$t"]["Bus_"*l_id]["time_series"]*sqrt(1-(l["cosphi"])^2))
        end
        result_timesteps_dc["$t"] = deepcopy(_PMACDC.run_acdcopf(test_case_timestep, DCPPowerModel, gurobi; setting = s))
        result_timesteps_ac["$t"] = deepcopy(_PMACDC.run_acdcopf(test_case_timestep, ACPPowerModel, ipopt; setting = s))
    end

    string_data = JSON.json(result_timesteps_dc)
    open(output_filename*"_DCPPowerModel_$(length(timesteps))_timesteps_$(conv_power)_GW_convdc.json","w" ) do f
        write(f,string_data)
    end

    string_data = JSON.json(result_timesteps_ac)
    open(output_filename*"_ACPPowerModel_$(length(timesteps))_timesteps_$(conv_power)_GW_convdc.json","w" ) do f
        write(f,string_data)
    end
    return result_timesteps_dc, result_timesteps_ac
end

result_dc, result_ac = solve_opf_timestep(test_case,selected_timesteps_RES_time_series,selected_timesteps_load_time_series,timesteps,conv_power)
    


