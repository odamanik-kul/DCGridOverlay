using Plots

plot_markersize = 7
plot_fontfamily = "Computer Modern"
plot_titlefontsize = 20
plot_guidefontsize = 16
plot_tickfontsize = 12
plot_legendfontsize = 12

# Plot branchdc flow normalized
for bd in branchdc_ids
    branchdc_name = grid["branchdc"][bd]["name"]
    plot_branchdc_nowm_pf = scatter(1:n_time_steps,results["branchdc_norm"][bd]["pf"],
                        legend=false,alpha=0.2,markerstrokewidth=0,ylims=(-1.2,1.2),
                        framestyle=:box,
                        # legend=plot_legend,
                        # palette=cgrad(:default, length(gen_ids), categorical = true),
                        fontfamily=plot_fontfamily,
                        # background_color=:transparent,
                        foreground_color=:black,
                        titlefontsize = plot_titlefontsize,
                        guidefontsize = plot_guidefontsize,
                        tickfontsize = plot_tickfontsize,
                        legendfontsize = plot_legendfontsize,)
    title!(branchdc_name)
    xlabel!("Time")
    ylabel!("Loading [p.u.]")
    Plots.svg(joinpath("./test_cases/initial_results/$case_name","branchdc_flow_norm_-$branchdc_name.svg"))
end
# Plot branch flow - Normalized
for b in branch_ids
    branch_name = grid["branch"][b]["name"]
    plot_branch_pf = scatter(1:n_time_steps,results["branch"][b]["pf"],
                        legend=false,alpha=0.2,markerstrokewidth=0,ylims=(-0.1,0.1),
                        framestyle=:box,
                        # legend=plot_legend,
                        # palette=cgrad(:default, length(gen_ids), categorical = true),
                        fontfamily=plot_fontfamily,
                        # background_color=:transparent,
                        foreground_color=:black,
                        titlefontsize = plot_titlefontsize,
                        guidefontsize = plot_guidefontsize,
                        tickfontsize = plot_tickfontsize,
                        legendfontsize = plot_legendfontsize)
    title!(branch_name)
    xlabel!("Time")
    ylabel!("Loading [p.u.]")
    Plots.svg(joinpath("./test_cases/initial_results/$case_name","branch_flow_norm_-$branch_name.svg"))
end

# Plot branchdc flow
for bd in branchdc_ids
    branchdc_name = grid["branchdc"][bd]["name"]
    plot_branchdc_pf = scatter(1:n_time_steps,results["branchdc"][bd]["pf"], legend=false, alpha=0.6,markerstrokewidth=0,ylims=(-200,200))
    title!(branchdc_name)
    Plots.svg(joinpath("./test_cases/initial_results/$case_name","branchdc_flow_-$branchdc_name.svg"))
end
# Plot branch flow
for b in branch_ids
    branch_name = grid["branch"][b]["name"]
    plot_branch_pf = scatter(1:n_time_steps,results["branch"][b]["pf"], legend=false, alpha=0.6,markerstrokewidth=0,ylims=(-200,200))
    title!(branch_name)
    Plots.svg(joinpath("./test_cases/initial_results/$case_name","branch_flow_-$branch_name.svg"))
end

# # plot_conv_vmconv = scatter(1:n_time_steps,results["convdc"]["4"]["vmconv"],ylims=(0.85,1.05), legend=false)
# plot_busdc_vm = scatter(1:n_time_steps,results["busdc"]["5"]["vm"],ylims=(0.85,1.05), legend=false)
# # plot_branchdc_pabs = scatter(1:n_time_steps,results["branchdc"]["9"]["pabs"],ylims=(0,200), legend=false)
# plot_branchdc_pf = scatter(1:n_time_steps,results["branchdc"]["1"]["pf"], legend=false, alpha=0.6,markerstrokewidth=0)

# plot_branch_pabs = scatter(1:n_time_steps,results["branch"]["8"]["pabs"],ylims=(0,200), legend=false)