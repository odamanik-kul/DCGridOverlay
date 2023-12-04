using JSON
using JSON3
using CbaOPF

include("create_grid_and_opf_functions.jl")
include("processing_results_function.jl")

#########################################################################################################################
# One can choose the Pmax of the conv_power among 2.0, 4.0 and 8.0 GW
conv_power = 6.0
########################################################################
# Uploading test case
########################################################################
test_case_file = "DC_overlay_grid_$(conv_power)_GW_convdc.json"
test_case = _PM.parse_file("./test_cases/$test_case_file")

########################################################################
# Uploading results
########################################################################
results_file_ac = "/Users/giacomobastianel/.julia/dev/DCGridOverlay/results/result_one_year_AC_grid.json"
results_file_ac_dc = "/Users/giacomobastianel/.julia/dev/DCGridOverlay/results/result_one_year_AC_DC_grid.json"

results_AC = Dict()
open(results_file_ac, "r") do f
    global results_AC
    dicttxt = read(f,String)  # file information to string
    results_AC=JSON.parse(dicttxt)  # parse and transform data
end

results_AC_DC = Dict()
open(results_file_ac_dc, "r") do f
    global results_AC_DC
    dicttxt_ = read(f,String)  # file information to string
    results_AC_DC=JSON.parse(dicttxt_)  # parse and transform data
end

########################################################################
# Computing the total generation costs
########################################################################
obj_ac = sum(r["objective"]*100 for (r_id,r) in results_AC)
obj_ac_dc = sum(r["objective"]*100 for (r_id,r) in results_AC_DC)

benefit = (obj_ac - obj_ac_dc)/10^9

print("The total benefits for the selected year are $(benefit) billions")

########################################################################
# Computing VOLL for each hour
########################################################################
hourly_voll_ac = []
hourly_voll_ac_dc = []

compute_VOLL(test_case,8760,results_AC,hourly_voll_ac)
compute_VOLL(test_case,8760,results_AC_DC,hourly_voll_ac_dc)

sum(hourly_voll_ac)
sum(hourly_voll_ac_dc)

########################################################################
# Computing CO2 emissions for each hour
########################################################################
# Adding and assigning generator values
gen_costs,inertia_constants,emission_factor_CO2,start_up_cost,emission_factor_NOx,emission_factor_SOx = gen_values()
assigning_gen_values(test_case)

hourly_CO2_ac = []
hourly_CO2_ac_dc = []

compute_CO2_emissions(test_case,8760,results_AC,hourly_CO2_ac)
compute_CO2_emissions(test_case,8760,results_AC_DC,hourly_CO2_ac_dc)

sum(hourly_CO2_ac)
sum(hourly_CO2_ac_dc)

CO2_reduction = (sum(hourly_CO2_ac)-sum(hourly_CO2_ac_dc))/10^6 # Mton

print("The reduction of the CO2 emissions for the selected year are $(CO2_reduction) Mton")
########################################################################
# Computing RES generation for each hour
########################################################################
hourly_RES_ac = []
hourly_RES_ac_dc = []

compute_RES_generation(test_case,8760,results_AC,hourly_RES_ac)
compute_RES_generation(test_case,8760,results_AC_DC,hourly_RES_ac_dc)

sum(hourly_RES_ac)
sum(hourly_RES_ac_dc)

RES_curtailment = (sum(hourly_RES_ac_dc)-sum(hourly_RES_ac))/10^3 # TWh

print("The curtailment of the RES generation for the selected year are $(RES_curtailment) TWh")

########################################################################
# Computing NOx emissions for each hour
########################################################################
hourly_NOx_ac = []
hourly_NOx_ac_dc = []

compute_NOx_emissions(test_case,8760,results_AC,hourly_NOx_ac)
compute_NOx_emissions(test_case,8760,results_AC_DC,hourly_NOx_ac_dc)

sum(hourly_NOx_ac)
sum(hourly_NOx_ac_dc)

NOx_reduction = (sum(hourly_NOx_ac)-sum(hourly_NOx_ac_dc))/10^6 # Mton

print("The reduction of the NOx emissions for the selected year are $(NOx_reduction) Mton")

########################################################################
# Computing SOx emissions for each hour
########################################################################
hourly_SOx_ac = []
hourly_SOx_ac_dc = []

compute_SOx_emissions(test_case,8760,results_AC,hourly_SOx_ac)
compute_SOx_emissions(test_case,8760,results_AC_DC,hourly_SOx_ac_dc)

sum(hourly_SOx_ac)
sum(hourly_SOx_ac_dc)

SOx_reduction = (sum(hourly_SOx_ac)-sum(hourly_SOx_ac_dc))/10^6 # Mton

print("The reduction of the CO2 emissions for the selected year are $(CO2_reduction) Mton")

########################################################################
# Computing congestions for each hour
########################################################################
congested_lines_ac = []
congested_lines_ac_dc = []

compute_congestions(test_case,8760,results_AC,hourly_SOx_ac)
compute_congestions(test_case,8760,results_AC_DC,hourly_SOx_ac_dc)

sum(hourly_SOx_ac)
sum(hourly_SOx_ac_dc)

SOx_reduction = (sum(hourly_SOx_ac)-sum(hourly_SOx_ac_dc))/10^6 # Mton

print("The reduction of the CO2 emissions for the selected year are $(CO2_reduction) Mton")
