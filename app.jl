using GenieFramework
using .FinancialFormulas
@genietools

# Define the Investor type
mutable struct Investor
    name::String
    amount::Float64
    equity::Float64
    monthly_profit::Float64
    breakeven_years::Int
    breakeven_months::Int
    breakeven_days::Int
end

# Constructor with defaults
function Investor(; name="", amount=0.0)
    Investor(name, amount, 0.0, 0.0, 0, 0, 0)
end

# Define the OperatingCost type
mutable struct OperatingCost
    name::String
    amount::Float64
end

# Constructor with defaults
function OperatingCost(; name="", amount=0.0)
    OperatingCost(name, amount)
end

@app begin
    @in activeTab::String = "setup"
    
    # Property Setup
    @in land_cost::Float64 = 800000.0
    @in num_rooms::Int = 6
    @in nightly_rate::Float64 = 90.0
    @in occupancy_rate::Float64 = 0.6
    @in annual_appreciation::Float64 = 3.0
    
    # Horse Operations
    @in monthly_treks::Int = 4
    @in people_per_trek::Int = 5
    @in cost_per_person::Float64 = 80.0
    
    # Investment Structure
    @out investors::Vector{Investor} = []
    @in new_investor_name::String = ""
    @in new_investor_amount::Float64 = 0.0
    @in add_investor::Bool = false
    
    # Operating Costs
    @out operating_costs::Vector{OperatingCost} = []
    @in new_cost_name::String = ""
    @in new_cost_amount::Float64 = 0.0
    @in add_cost::Bool = false
    
    # Financial Overview
    @out monthly_revenue::Float64 = 0.0
    @out monthly_operating_costs::Float64 = 0.0
    @out monthly_profit::Float64 = 0.0
    
    # Property Value Projections
    @out year1_value::Float64 = 0.0
    @out year3_value::Float64 = 0.0
    @out year5_value::Float64 = 0.0
    @out year10_value::Float64 = 0.0
    @out years::Vector{Int} = [0, 1, 3, 5, 10]
    @out values::Vector{Float64} = Float64[]
    
    # Chart data
    @out investment_plot = []
    @out financial_labels::Vector{String} = ["Revenue", "Operating Costs", "Net Profit"]
    @out financial_values::Vector{Float64} = [0.0, 0.0, 0.0]
    @out financial_colors::Vector{String} = ["rgb(61, 185, 100)", "rgb(201, 90, 218)", "rgb(54, 162, 235)"]
    @out property_chart_data = []
    @out property_chart_layout = Dict(
        "title" => Dict("text" => "Property Value Over Time"),
        "xaxis" => Dict("title" => Dict("text" => "Years")),
        "yaxis" => Dict("title" => Dict("text" => "Value"))
    )

    @onchange isready begin
        investors = [
            Investor(name="Mulligan", amount=610000.0),
            Investor(name="Pat", amount=100000.0),
            Investor(name="Colleen", amount=40000.0),
            Investor(name="Charlie", amount=50000.0)
        ]
        
        operating_costs = [
            OperatingCost(name="Property Management", amount=1000.0),
            OperatingCost(name="Maintenance", amount=500.0),
            OperatingCost(name="Utilities", amount=600.0),
            OperatingCost(name="Insurance", amount=200.0),
            OperatingCost(name="Property Tax", amount=200.0)
        ]
        
        monthly_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        monthly_operating_costs = update_operating_costs(operating_costs)
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
        
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        
        property_chart_data = [Dict(
            "x" => years,
            "y" => values,
            "mode" => "lines+markers",
            "type" => "scatter",
            "name" => "Property Value",
            "line" => Dict("color" => "rgb(61, 185, 100)", "width" => 2),
            "marker" => Dict("size" => 8)
        )]
    end

    @onchange num_rooms begin
        monthly_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        monthly_profit = monthly_revenue - monthly_operating_costs
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange nightly_rate begin
        monthly_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        monthly_profit = monthly_revenue - monthly_operating_costs
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange occupancy_rate begin
        monthly_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        monthly_profit = monthly_revenue - monthly_operating_costs
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange land_cost begin
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        property_chart_data = [Dict(
            "x" => years,
            "y" => values,
            "mode" => "lines+markers",
            "type" => "scatter",
            "name" => "Property Value",
            "line" => Dict("color" => "rgb(61, 185, 100)", "width" => 2),
            "marker" => Dict("size" => 8)
        )]
    end

    @onchange annual_appreciation begin
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        property_chart_data = [Dict(
            "x" => years,
            "y" => values,
            "mode" => "lines+markers",
            "type" => "scatter",
            "name" => "Property Value",
            "line" => Dict("color" => "rgb(61, 185, 100)", "width" => 2),
            "marker" => Dict("size" => 8)
        )]
    end

    @onchange add_investor begin
        if !isempty(new_investor_name) && new_investor_amount > 0
            push!(investors, Investor(name=new_investor_name, amount=new_investor_amount))
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
        end
    end

    @onchange add_cost begin
        if !isempty(new_cost_name) && new_cost_amount > 0
            push!(operating_costs, OperatingCost(name=new_cost_name, amount=new_cost_amount))
            monthly_operating_costs = update_operating_costs(operating_costs)
            monthly_profit = monthly_revenue - monthly_operating_costs
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
        end
    end
end

@page("/", "app.jl.html")