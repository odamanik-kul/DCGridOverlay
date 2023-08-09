# Script to create the DC grid overlay project's grid
# Refer to the excel file in the package
# 7th August 2023
using XLSX
using PowerModels; const _PM = PowerModels
using PowerModelsACDC; const _PMACDC = PowerModelsACDC
using JSON
using JuMP
using CbaOPF

function create_grid(start_hour,number_of_hours;output_filename::String = "./test_cases/DC_overlay_grid")
    # Uploading an example test system
    test_case_5_acdc = "case5_acdc.m"
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    data_file_5_acdc = "./test_cases/$test_case_5_acdc"
    test_grid = _PM.parse_file(joinpath("./$(data_file_5_acdc)"))
    _PMACDC.process_additional_data!(test_grid)

    test_file = "./test_cases/DC_overlay_grid.xlsx"
    #test_grid = _PM.parse_file(test_file)

    # Calling the Excel file
    xf = XLSX.readxlsx(joinpath("./$(test_file)"))
    XLSX.sheetnames(xf)
    number_of_buses = 6

    # Creating a European grid dictionary in PowerModels format
    DC_overlay_grid = Dict{String,Any}()
    DC_overlay_grid["dcpol"] = 2
    DC_overlay_grid["name"] = "DC_overlay_grid"
    DC_overlay_grid["baseMVA"] = 100
    DC_overlay_grid["base_kv_AC"] = 380
    DC_overlay_grid["base_kv_DC"] = 525
    DC_overlay_grid["per_unit"] = true #adapt values from Excel file
    DC_overlay_grid["Z_base"] = (DC_overlay_grid["base_kv_AC"])^2/(DC_overlay_grid["baseMVA"]*1000)
    

    # Buses
    DC_overlay_grid["bus"] = Dict{String,Any}()
    for idx in 1:number_of_buses
        DC_overlay_grid["bus"]["$idx"] = Dict{String,Any}()
        DC_overlay_grid["bus"]["$idx"]["name"] = "Bus_$(idx)"
        DC_overlay_grid["bus"]["$idx"]["index"] = idx 
        DC_overlay_grid["bus"]["$idx"]["bus_i"] = idx 
        if idx == 3
            DC_overlay_grid["bus"]["$idx"]["bus_type"] = 3 #slack bus
        else
            DC_overlay_grid["bus"]["$idx"]["bus_type"] = 1 
        end
        DC_overlay_grid["bus"]["$idx"]["pd"] = 0.0 
        DC_overlay_grid["bus"]["$idx"]["qd"] = 0.0 
        DC_overlay_grid["bus"]["$idx"]["gs"] = 0.0 
        DC_overlay_grid["bus"]["$idx"]["bs"] = 0.0 
        DC_overlay_grid["bus"]["$idx"]["area"] = 1 
        DC_overlay_grid["bus"]["$idx"]["vm"] = 1.0
        DC_overlay_grid["bus"]["$idx"]["va"] = 1.0
        DC_overlay_grid["bus"]["$idx"]["base_kv"] = 380 #kV
        DC_overlay_grid["bus"]["$idx"]["vmax"] = 1.1
        DC_overlay_grid["bus"]["$idx"]["vmin"] = 0.9
        DC_overlay_grid["bus"]["$idx"]["source_id"] = []
        push!(DC_overlay_grid["bus"]["$idx"]["source_id"],"bus")
        push!(DC_overlay_grid["bus"]["$idx"]["source_id"],idx)
    end

    # Bus dc -> it can be commented out if you want to keep only the AC system
    DC_overlay_grid["busdc"] = Dict{String,Any}()
    for idx in 1:number_of_buses
        DC_overlay_grid["busdc"]["$idx"] = Dict{String,Any}()
        DC_overlay_grid["busdc"]["$idx"]["name"] = "Bus_dc_$(idx)"
        DC_overlay_grid["busdc"]["$idx"]["index"] = idx
        DC_overlay_grid["busdc"]["$idx"]["busdc_i"] = idx
        DC_overlay_grid["busdc"]["$idx"]["bus_type"] = 1
        DC_overlay_grid["busdc"]["$idx"]["pd"] = 0.0
        DC_overlay_grid["busdc"]["$idx"]["qd"] = 0.0
        DC_overlay_grid["busdc"]["$idx"]["gs"] = 0.0
        DC_overlay_grid["busdc"]["$idx"]["bs"] = 0.0
        DC_overlay_grid["busdc"]["$idx"]["area"] = 2
        DC_overlay_grid["busdc"]["$idx"]["vm"] = 1.0
        DC_overlay_grid["busdc"]["$idx"]["Vdcmax"] = 1.1
        DC_overlay_grid["busdc"]["$idx"]["Vdcmin"] = 0.9
        DC_overlay_grid["busdc"]["$idx"]["Vdc"] = 1
        DC_overlay_grid["busdc"]["$idx"]["Pdc"] = 0
        DC_overlay_grid["busdc"]["$idx"]["Cdc"] = 0
        DC_overlay_grid["busdc"]["$idx"]["source_id"] = []
        push!(DC_overlay_grid["busdc"]["$idx"]["source_id"],"busdc")
        push!(DC_overlay_grid["busdc"]["$idx"]["source_id"],idx)
    end

    # Branches
    DC_overlay_grid["branch"] = Dict{String,Any}()
    for r in XLSX.eachrow(xf["AC_grid_build"])
        i = XLSX.row_number(r)
        if i > 1 && i <= 9 
            # compensate for header and limit the number of rows to the existing branches
            idx = i - 1
            DC_overlay_grid["branch"]["$idx"] = Dict{String,Any}()
            DC_overlay_grid["branch"]["$idx"]["type"] = "AC_line"
            DC_overlay_grid["branch"]["$idx"]["index"] = idx
            DC_overlay_grid["branch"]["$idx"]["f_bus"] = parse(Int64,r[1][3])
            DC_overlay_grid["branch"]["$idx"]["t_bus"] = parse(Int64,r[1][4])
            DC_overlay_grid["branch"]["$idx"]["br_r"] = r[7]*r[3]/DC_overlay_grid["Z_base"]   
            DC_overlay_grid["branch"]["$idx"]["br_x"] = r[8]*r[3]/DC_overlay_grid["Z_base"]   
            DC_overlay_grid["branch"]["$idx"]["b_fr"] = 0.0 #1/sqrt((DC_overlay_grid["branch"]["$idx"]["br_r"])^2+(DC_overlay_grid["branch"]["$idx"]["br_x"])^2) 
            DC_overlay_grid["branch"]["$idx"]["b_to"] = 0.0 #1/sqrt((DC_overlay_grid["branch"]["$idx"]["br_r"])^2+(DC_overlay_grid["branch"]["$idx"]["br_x"])^2)
            DC_overlay_grid["branch"]["$idx"]["g_fr"] = 0.0
            DC_overlay_grid["branch"]["$idx"]["g_to"] = 0.0
            DC_overlay_grid["branch"]["$idx"]["rate_a"] = r[2]/DC_overlay_grid["baseMVA"]
            DC_overlay_grid["branch"]["$idx"]["rate_b"] = r[2]/DC_overlay_grid["baseMVA"] 
            DC_overlay_grid["branch"]["$idx"]["rate_c"] = r[2]/DC_overlay_grid["baseMVA"]
            DC_overlay_grid["branch"]["$idx"]["ratio"] = 1 
            DC_overlay_grid["branch"]["$idx"]["angmin"] = -pi
            DC_overlay_grid["branch"]["$idx"]["angmax"] = pi 
            DC_overlay_grid["branch"]["$idx"]["br_status"] = 1
            DC_overlay_grid["branch"]["$idx"]["tap"] = 1.0
            DC_overlay_grid["branch"]["$idx"]["transformer"] = false
            DC_overlay_grid["branch"]["$idx"]["shift"] = 0.0
            DC_overlay_grid["branch"]["$idx"]["source_id"] = []
            push!(DC_overlay_grid["branch"]["$idx"]["source_id"],"branch")
            push!(DC_overlay_grid["branch"]["$idx"]["source_id"], idx)
        end
    end

    # DC Branches
    DC_overlay_grid["branchdc"] = Dict{String,Any}()
    for r in XLSX.eachrow(xf["DC_grid_build"])
        i = XLSX.row_number(r)
        if i > 1 && i <= 9 # compensate for header and limit the number of rows to the existing branches
            idx = i - 1
            DC_overlay_grid["branchdc"]["$idx"] = Dict{String,Any}()
            DC_overlay_grid["branchdc"]["$idx"]["type"] = "DC_line" #branches_dc_dict[:,2][i]
            DC_overlay_grid["branchdc"]["$idx"]["index"] = idx
            DC_overlay_grid["branchdc"]["$idx"]["fbusdc"] = parse(Int64,r[1][3])
            DC_overlay_grid["branchdc"]["$idx"]["tbusdc"] = parse(Int64,r[1][4])
            DC_overlay_grid["branchdc"]["$idx"]["r"] = r[6]*r[3]/DC_overlay_grid["Z_base"]
            DC_overlay_grid["branchdc"]["$idx"]["c"] = 0.0
            DC_overlay_grid["branchdc"]["$idx"]["l"] = 0.0
            DC_overlay_grid["branchdc"]["$idx"]["status"] = 1
            DC_overlay_grid["branchdc"]["$idx"]["rateA"] = r[2]/DC_overlay_grid["baseMVA"] # Total [MVA] (+/-)
            DC_overlay_grid["branchdc"]["$idx"]["rateB"] = r[2]/DC_overlay_grid["baseMVA"] # Total [MVA] (+/-)
            DC_overlay_grid["branchdc"]["$idx"]["rateC"] = r[2]/DC_overlay_grid["baseMVA"] # Total [MVA] (+/-)
            DC_overlay_grid["branchdc"]["$idx"]["ratio"] = 1
            DC_overlay_grid["branchdc"]["$idx"]["source_id"] = []
            push!(DC_overlay_grid["branchdc"]["$idx"]["source_id"],"branchdc")
            push!(DC_overlay_grid["branchdc"]["$idx"]["source_id"], idx)
        end
    end

    # DC Converters
    DC_overlay_grid["convdc"] = Dict{String,Any}()
    for r in XLSX.eachrow(xf["Conv_dc"])
        i = XLSX.row_number(r)
        if i > 1 && i <= 7 # compensate for header and limit the number of rows to the existing branches
            idx = i - 1    
            DC_overlay_grid["convdc"]["$idx"] = Dict{String,Any}()
            DC_overlay_grid["convdc"]["$idx"] = deepcopy(test_grid["convdc"]["1"])  # To fill in default values......
            DC_overlay_grid["convdc"]["$idx"]["busdc_i"] = idx 
            DC_overlay_grid["convdc"]["$idx"]["busac_i"] = idx 
            DC_overlay_grid["convdc"]["$idx"]["index"] = idx
            DC_overlay_grid["convdc"]["$idx"]["status"] = 1
            sum = 0
            for (brdc_id,brdc) in DC_overlay_grid["branchdc"]
                if brdc["fbusdc"] == idx || brdc["tbusdc"] == idx 
                    sum = sum + brdc["rateA"]
                end
            end 
            DC_overlay_grid["convdc"]["$idx"]["Pacmax"] = deepcopy(sum) # Values to not having this power constraining the OPF -> sum of the capacities coming in and going out
            DC_overlay_grid["convdc"]["$idx"]["Pacmin"] = - deepcopy(sum)
            DC_overlay_grid["convdc"]["$idx"]["Qacmin"] = - deepcopy(sum)
            DC_overlay_grid["convdc"]["$idx"]["Qacmax"] = deepcopy(sum)
            DC_overlay_grid["convdc"]["$idx"]["Pg"] = 0.0 #Adjusting with pu values
            DC_overlay_grid["convdc"]["$idx"]["ratio"] = 1
            DC_overlay_grid["convdc"]["$idx"]["transformer"] = 1
            DC_overlay_grid["convdc"]["$idx"]["reactor"] = 1
            DC_overlay_grid["convdc"]["$idx"]["source_id"] = []
            push!(DC_overlay_grid["convdc"]["$idx"]["source_id"],"convdc")
            push!(DC_overlay_grid["convdc"]["$idx"]["source_id"], idx)

            # Computed with Hakan's excel
            #DC_overlay_grid["convdc"]["$idx"]["rtf"] = r[2] 
            #DC_overlay_grid["convdc"]["$idx"]["xtf"] = r[3] 
            #DC_overlay_grid["convdc"]["$idx"]["bf"] = r[4] 
            #DC_overlay_grid["convdc"]["$idx"]["rc"] = r[5]
            #DC_overlay_grid["convdc"]["$idx"]["xc"] = r[6]
            #DC_overlay_grid["convdc"]["$idx"]["lossA"] = r[7]/DC_overlay_grid["baseMVA"] 
            #DC_overlay_grid["convdc"]["$idx"]["lossB"] = r[8]
            #DC_overlay_grid["convdc"]["$idx"]["lossCrec"] = r[9] 
        end
    end

    # Load
    loads = ["I","J","K","L","M","N"]
    DC_overlay_grid["load"] = Dict{String,Any}()
    for idx in 1:length(loads)
        DC_overlay_grid["load"]["$idx"] = Dict{String,Any}()
        DC_overlay_grid["load"]["$idx"]["load_bus"] = idx #load_dict[:,3][i]
        DC_overlay_grid["load"]["$idx"]["pmax"] = xf["Demand"]["$(loads[idx])2"]/DC_overlay_grid["baseMVA"]
        DC_overlay_grid["load"]["$idx"]["pavg"] = xf["Demand"]["$(loads[idx])5"]/DC_overlay_grid["baseMVA"]
        DC_overlay_grid["load"]["$idx"]["cosphi"] = 0.9
        DC_overlay_grid["load"]["$idx"]["pd"] = DC_overlay_grid["load"]["$idx"]["pmax"]/2 # load_dict[:,4][i]/DC_overlay_grid["baseMVA"] 
        DC_overlay_grid["load"]["$idx"]["qd"] = (DC_overlay_grid["load"]["$idx"]["pmax"]/2)*sqrt(1 - DC_overlay_grid["load"]["$idx"]["cosphi"]^2)
        DC_overlay_grid["load"]["$idx"]["index"] = idx
        DC_overlay_grid["load"]["$idx"]["status"] = 1
        DC_overlay_grid["load"]["$idx"]["source_id"] = []
        push!(DC_overlay_grid["load"]["$idx"]["source_id"],"bus")
        push!(DC_overlay_grid["load"]["$idx"]["source_id"], idx)
    end

    # Sort time series
    demands = ["A","B","C","D","E","F"]
    total_demand = ["G"]
    demand_time_series = Dict{String,Any}()
    total_demand_time_series = Dict{String,Any}()
    for idx in 1:length(demands)
        demand_time_series["Bus_$idx"] = []
        for h in (start_hour+1):(number_of_hours+1)
            push!(demand_time_series["Bus_$idx"],xf["Demand"]["$(demands[idx])$(h)"]/DC_overlay_grid["baseMVA"])
        end
    end
    for idx in 1:length(total_demand)
        total_demand_time_series["Total_demand"] = []
        for h in 2:number_of_hours
            push!(total_demand_time_series["Total_demand"],xf["Demand"]["$(total_demand[idx])$(h)"]/DC_overlay_grid["baseMVA"])
        end
    end

    ####### READ IN GENERATION DATA #######################
    solar_pv = ["B","E","H","K","N","Q"]
    onshore_wind = ["C","F","I","L","O","R"]
    offshore_wind = ["D","G","J","M","P","S"]
    DC_overlay_grid["gen"] = Dict{String,Any}()
    count_ = 0

    ##### Solar PV  #####
    for idx in 1:length(solar_pv) 
        count_ += 1
        DC_overlay_grid["gen"]["$idx"] = Dict{String,Any}()
        DC_overlay_grid["gen"]["$idx"]["index"] =   deepcopy(idx)
        DC_overlay_grid["gen"]["$idx"]["gen_bus"] = deepcopy(idx) 
        DC_overlay_grid["gen"]["$idx"]["pmax"] = xf["RES_MVA"]["$(solar_pv[idx])2"]/DC_overlay_grid["baseMVA"]
        DC_overlay_grid["gen"]["$idx"]["pmin"] = 0.0 
        DC_overlay_grid["gen"]["$idx"]["qmax"] =  DC_overlay_grid["gen"]["$idx"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$idx"]["qmin"] = -DC_overlay_grid["gen"]["$idx"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$idx"]["cost"] = [0.0, 0.0]
        DC_overlay_grid["gen"]["$idx"]["marginal_cost"] = 0.0
        DC_overlay_grid["gen"]["$idx"]["co2_add_on"] = 0.0
        DC_overlay_grid["gen"]["$idx"]["ncost"] = 2
        DC_overlay_grid["gen"]["$idx"]["model"] = 2
        DC_overlay_grid["gen"]["$idx"]["type"] = "Solar PV"
        DC_overlay_grid["gen"]["$idx"]["gen_status"] = 1
        DC_overlay_grid["gen"]["$idx"]["vg"] = 1.0
        DC_overlay_grid["gen"]["$idx"]["source_id"] = []
        DC_overlay_grid["gen"]["$idx"]["name"] = "Solar_PV_$(idx)"  # Assumption here, to be checked
        push!(DC_overlay_grid["gen"]["$idx"]["source_id"],"gen")
        push!(DC_overlay_grid["gen"]["$idx"]["source_id"], idx)
    end
    ##### Onshore Wind  #####
    for idx in 1:length(onshore_wind) 
        count_ += 1
        DC_overlay_grid["gen"]["$count_"] = Dict{String,Any}()
        DC_overlay_grid["gen"]["$count_"]["index"]  = deepcopy(count_)
        DC_overlay_grid["gen"]["$count_"]["gen_bus"] = deepcopy(idx) 
        DC_overlay_grid["gen"]["$count_"]["pmax"] = xf["RES_MVA"]["$(onshore_wind[idx])2"]/DC_overlay_grid["baseMVA"]
        DC_overlay_grid["gen"]["$count_"]["pmin"] = 0.0 
        DC_overlay_grid["gen"]["$count_"]["qmax"] =  DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["qmin"] = -DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["cost"] = [0.0, 0.0]
        DC_overlay_grid["gen"]["$count_"]["marginal_cost"] = 0.0
        DC_overlay_grid["gen"]["$count_"]["co2_add_on"] = 0.0
        DC_overlay_grid["gen"]["$count_"]["ncost"] = 2
        DC_overlay_grid["gen"]["$count_"]["model"] = 2
        DC_overlay_grid["gen"]["$count_"]["type"] = "Onshore Wind"
        DC_overlay_grid["gen"]["$count_"]["gen_status"] = 1
        DC_overlay_grid["gen"]["$count_"]["vg"] = 1.0
        DC_overlay_grid["gen"]["$count_"]["source_id"] = []
        DC_overlay_grid["gen"]["$count_"]["name"] = "Onshore_Wind_$(idx)"  # Assumption here, to be checked
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"],"gen")
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"], count_)
    end
    ##### Offshore Wind  #####
    for idx in 1:length(offshore_wind) 
        count_ += 1
        DC_overlay_grid["gen"]["$count_"] = Dict{String,Any}()
        DC_overlay_grid["gen"]["$count_"]["index"] = deepcopy(count_)
        DC_overlay_grid["gen"]["$count_"]["gen_bus"] = deepcopy(idx) 
        DC_overlay_grid["gen"]["$count_"]["pmax"] = xf["RES_MVA"]["$(offshore_wind[idx])2"]/DC_overlay_grid["baseMVA"]
        DC_overlay_grid["gen"]["$count_"]["pmin"] = 0.0 
        DC_overlay_grid["gen"]["$count_"]["qmax"] =  DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["qmin"] = -DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["cost"] = [0.0, 0.0]
        DC_overlay_grid["gen"]["$count_"]["marginal_cost"] = 0.0
        DC_overlay_grid["gen"]["$count_"]["co2_add_on"] = 0.0
        DC_overlay_grid["gen"]["$count_"]["ncost"] = 2
        DC_overlay_grid["gen"]["$count_"]["model"] = 2
        DC_overlay_grid["gen"]["$count_"]["type"] = "Offshore Wind"
        DC_overlay_grid["gen"]["$count_"]["gen_status"] = 1
        DC_overlay_grid["gen"]["$count_"]["vg"] = 1.0
        DC_overlay_grid["gen"]["$count_"]["source_id"] = []
        DC_overlay_grid["gen"]["$count_"]["name"] = "Offshore_Wind_$(idx)"  # Assumption here, to be checked
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"],"gen")
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"], count_)
    end
    ##### Conventional gens  #####
    for idx in 1:length(solar_pv) 
        count_ += 1
        DC_overlay_grid["gen"]["$count_"] = Dict{String,Any}()
        DC_overlay_grid["gen"]["$count_"]["index"] = deepcopy(count_)
        DC_overlay_grid["gen"]["$count_"]["gen_bus"] = deepcopy(idx) # SUM OF THE ENTSO-E TYNDP CAPACITY
        DC_overlay_grid["gen"]["$count_"]["pmax"] = 5*10^5/DC_overlay_grid["baseMVA"] #High value to always have adequacy, assumption, to be discussed
        DC_overlay_grid["gen"]["$count_"]["pmin"] = 0.0 
        DC_overlay_grid["gen"]["$count_"]["qmax"] =  DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["qmin"] = -DC_overlay_grid["gen"]["$count_"]["pmax"]*0.5
        DC_overlay_grid["gen"]["$count_"]["cost"] = [10.0, 0.0] # Made-up values
        DC_overlay_grid["gen"]["$count_"]["marginal_cost"] = 2.0 # Made-up values
        DC_overlay_grid["gen"]["$count_"]["co2_add_on"] = 1.0 # Made-up values
        DC_overlay_grid["gen"]["$count_"]["ncost"] = 2
        DC_overlay_grid["gen"]["$count_"]["model"] = 2
        DC_overlay_grid["gen"]["$count_"]["type"] = "Conventional"
        DC_overlay_grid["gen"]["$count_"]["gen_status"] = 1
        DC_overlay_grid["gen"]["$count_"]["vg"] = 1.0
        DC_overlay_grid["gen"]["$count_"]["source_id"] = []
        DC_overlay_grid["gen"]["$count_"]["name"] = "Conventional_gen_$(idx)"  # Assumption here, to be checked
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"],"gen")
        push!(DC_overlay_grid["gen"]["$count_"]["source_id"], count_)
    end

    # Sort RES time series
    res_time_series = Dict{String,Any}()
    count_ = 0
    for idx in 1:length(solar_pv)
        count_ += 1
        res_time_series["$count_"] = Dict{String,Any}()
        res_time_series["$count_"]["name"] = "Solar_PV_$idx"
        res_time_series["$count_"]["time_series"] = []
        for h in (start_hour+1):(number_of_hours+1)
            push!(res_time_series["$count_"]["time_series"],xf["RES_PU"]["$(solar_pv[idx])$(h)"])
        end
    end
    for idx in 1:length(onshore_wind)
        count_ += 1
        res_time_series["$count_"] = Dict{String,Any}()
        res_time_series["$count_"]["name"] = "Onshore_Wind_$idx"
        res_time_series["$count_"]["time_series"] = []
        for h in (start_hour+1):(number_of_hours+1)
            push!(res_time_series["$count_"]["time_series"],xf["RES_PU"]["$(onshore_wind[idx])$(h)"])
        end
    end
    for idx in 1:length(offshore_wind)
        count_ += 1
        res_time_series["$count_"] = Dict{String,Any}()
        res_time_series["$count_"]["name"] = "Offshore_Wind_$idx"
        res_time_series["$count_"]["time_series"] = []
        for h in (start_hour+1):(number_of_hours+1)
            push!(res_time_series["$count_"]["time_series"],xf["RES_PU"]["$(offshore_wind[idx])$(h)"])
        end
    end

    ######
    # Making sure all the keys for PowerModels are there
    DC_overlay_grid["source_type"] = deepcopy(test_grid["source_type"])
    DC_overlay_grid["switch"] = deepcopy(test_grid["switch"])
    DC_overlay_grid["shunt"] = deepcopy(test_grid["shunt"])
    DC_overlay_grid["dcline"] = deepcopy(test_grid["dcline"])
    DC_overlay_grid["storage"] = deepcopy(test_grid["storage"])

    string_data = JSON.json(DC_overlay_grid)
    open(output_filename*".json","w" ) do f
        write(f,string_data)
    end

    string_data_demand = JSON.json(demand_time_series)
    open(output_filename*"_Demand_$(start_hour)_$(number_of_hours)"*".json","w" ) do f
        write(f,string_data_demand)
    end

    string_data_res = JSON.json(res_time_series)
    open(output_filename*"_RES_$(start_hour)_$(number_of_hours)"*".json","w" ) do f
        write(f,string_data_res)
    end
    return DC_overlay_grid, demand_time_series, res_time_series
end

function solve_opf_timestep(data,RES,load,timesteps;output_filename::String = "./results/OPF_results_selected_timesteps")
    result_timesteps = Dict{String,Any}()
    for t in timesteps
        test_case_timestep = deepcopy(data)
        for (g_id,g) in test_case_timestep["gen"]
            if g["type"] != "Conventional"
                g["pmax"] = deepcopy(g["pmax"]*RES[t][g_id]["time_series"])
                g["qmax"] = deepcopy(g["qmax"]*RES[t][g_id]["time_series"]) 
            end
        end
        for (l_id,l) in test_case_timestep["load"]
            l["pd"] = deepcopy(load[t]["Bus_"*l_id]["time_series"]*l["cosphi"])
            l["qd"] = deepcopy(load[t]["Bus_"*l_id]["time_series"]*sqrt(1-(l["cosphi"])^2))
        end
        result_timesteps["$t"] = deepcopy(_PMACDC.run_acdcopf(test_case_timestep, _PM.DCPPowerModel, gurobi; setting = s))
    end

    string_data = JSON.json(result_timesteps)
    open(output_filename*".json","w" ) do f
        write(f,string_data)
    end


    return result_timesteps
end

