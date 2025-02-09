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
    @in operationTab::String = "lodging"
    
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
    @out investors::Vector{Investor} = Investor[]  # Initialize as empty vector
    @in new_investor_name::String = ""
    @in new_investor_amount::Float64 = 0.0
    @in add_investor::Bool = false
    
    # Operating Costs
    @out operating_costs::Vector{OperatingCost} = OperatingCost[]  # Initialize as empty vector
    @in new_cost_name::String = ""
    @in new_cost_amount::Float64 = 0.0
    @in add_cost::Bool = false
    @in remove_cost::Bool = false
    
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

    # Add investment layout
    @out investment_layout = Dict(
        "title" => "Investment Distribution",
        "showlegend" => true
    )

    # Add a table_key to force table updates
    @out table_key::Int = 0

    # Add variable for tracking which cost to remove
    @in remove_cost_index::Int = -1

    # Add variable for tracking which investor to remove
    @in remove_investor::Bool = false
    @in remove_investor_index::Int = -1

    @onchange isready begin
        # Initialize default investors
        investors = [
            Investor(name="Mulligan", amount=610000.0),
            Investor(name="Pat", amount=100000.0),
            Investor(name="Coco", amount=40000.0),
            Investor(name="Charlie", amount=50000.0)
        ]
        
        # Initialize default operating costs
        operating_costs = [
            OperatingCost(name="Property Management", amount=1000.0),
            OperatingCost(name="Maintenance", amount=500.0),
            OperatingCost(name="Utilities", amount=600.0),
            OperatingCost(name="Insurance", amount=200.0),
            OperatingCost(name="Property Tax", amount=200.0)
        ]
        
        # Calculate initial revenues
        lodging_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        horse_revenue = calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
        monthly_revenue = lodging_revenue + horse_revenue
        
        # Calculate costs and profit
        monthly_operating_costs = update_operating_costs(operating_costs)
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        # Update all financial metrics and plots
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
        
        # Initialize property values
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        
        # Update property chart
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

    @onchange num_rooms, nightly_rate, occupancy_rate begin
        lodging_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        horse_revenue = calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
        monthly_revenue = lodging_revenue + horse_revenue
        
        monthly_operating_costs = update_operating_costs(operating_costs)
        monthly_profit = monthly_revenue - monthly_operating_costs
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange monthly_treks, people_per_trek, cost_per_person begin
        lodging_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
        horse_revenue = calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
        monthly_revenue = lodging_revenue + horse_revenue
        
        monthly_profit = monthly_revenue - monthly_operating_costs
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange land_cost begin
        # Update property values
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        
        # Update property chart
        property_chart_data = [Dict(
            "x" => years,
            "y" => values,
            "mode" => "lines+markers",
            "type" => "scatter",
            "name" => "Property Value",
            "line" => Dict("color" => "rgb(61, 185, 100)", "width" => 2),
            "marker" => Dict("size" => 8)
        )]

        # Update financial metrics since total investment changed
        monthly_operating_costs = update_operating_costs(operating_costs)
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        (financial_values, investors, investment_plot) = update_all_metrics(
            monthly_revenue, monthly_operating_costs, monthly_profit, investors
        )
    end

    @onchange annual_appreciation begin
        # Update property values
        (year1_value, year3_value, year5_value, year10_value, values) = calculate_property_values(
            land_cost, annual_appreciation
        )
        
        # Update property chart
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

    @onbutton add_investor begin
        if !isempty(new_investor_name) && new_investor_amount > 0
            # Create new investor
            new_investor = Investor(name=new_investor_name, amount=new_investor_amount)
            investors = [investors..., new_investor]
            
            # Update metrics once
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
            
            # Clear input fields
            new_investor_name = ""
            new_investor_amount = 0.0
        end
    end

    @onbutton add_cost begin
        if !isempty(new_cost_name) && new_cost_amount > 0
            # Create a new operating_costs array
            new_cost = OperatingCost(name=new_cost_name, amount=new_cost_amount)
            operating_costs = [operating_costs..., new_cost]
            
            # Single update of all dependent values
            monthly_operating_costs = update_operating_costs(operating_costs)
            monthly_profit = monthly_revenue - monthly_operating_costs
            
            # Update metrics
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
            
            # Clear input fields
            new_cost_name = ""
            new_cost_amount = 0.0
        end
    end

    @onbutton remove_cost begin
        if remove_cost_index >= 0 && remove_cost_index < length(operating_costs)
            # Remove specific cost by index
            operating_costs = [operating_costs[1:remove_cost_index]..., operating_costs[remove_cost_index+2:end]...]
            
            monthly_operating_costs = update_operating_costs(operating_costs)
            monthly_profit = monthly_revenue - monthly_operating_costs
            
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
            
            remove_cost_index = -1  # Reset index
        end
    end

    @onbutton remove_investor begin
        if remove_investor_index >= 0 && remove_investor_index < length(investors)
            # Remove specific investor by index
            investors = [investors[1:remove_investor_index]..., investors[remove_investor_index+2:end]...]
            
            (financial_values, investors, investment_plot) = update_all_metrics(
                monthly_revenue, monthly_operating_costs, monthly_profit, investors
            )
            
            # Reset
            remove_investor_index = -1
        end
    end
end

@page("/", "app.jl.html")
