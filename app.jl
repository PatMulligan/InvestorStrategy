module App

using GenieFramework
@genietools

# Helper functions need to be defined outside @app
function calculate_breakeven(amount, monthly_share)
    if monthly_share > 0
        total_days = (amount / monthly_share) * 30
        years = floor(Int, total_days / 365)
        remaining_days = total_days % 365
        months = floor(Int, remaining_days / 30)
        days = round(Int, remaining_days % 30)
        return (years, months, days)
    end
    return (999999, 0, 0)
end

function calculate_future_value(present_value, rate, years)
    return present_value * (1 + rate/100)^years
end

# Define the Investor type
Base.@kwdef mutable struct Investor
    name::String = ""
    amount::Float64 = 0.0
    equity::Float64 = 0.0
    monthly_profit::Float64 = 0.0
    breakeven_years::Int = 0
    breakeven_months::Int = 0
    breakeven_days::Int = 0
end

# Define the OperatingCost type
Base.@kwdef mutable struct OperatingCost
    name::String = ""
    amount::Float64 = 0.0
end

# Helper function to update plot and metrics
function update_plot(investors, monthly_profit)
    if !isempty(investors)
        total_investment = sum(i.amount for i in investors)
        
        # Update metrics for each investor
        for investor in investors
            investor.equity = (investor.amount / total_investment) * 100
            investor.monthly_profit = monthly_profit * (investor.equity / 100)
            
            # Calculate breakeven time
            (investor.breakeven_years, investor.breakeven_months, investor.breakeven_days) = 
                calculate_breakeven(investor.amount, investor.monthly_profit)
        end

        return [
            PlotData(
                labels=[i.name for i in investors],
                values=[i.amount for i in investors],
                plot=StipplePlotly.Charts.PLOT_TYPE_PIE,
                name="Investment Amount",
                hole=0.4,
                textinfo="label+percent",
                textfont=Font(color="white"),
                marker=PlotDataMarker(
                    colors=["#72C8A9", "#BD5631", "#54A2EB", "#FF9F40", "#9966FF"]
                )
            )
        ]
    else
        return [
            PlotData(
                labels=["No Investment"],
                values=[100],
                plot=StipplePlotly.Charts.PLOT_TYPE_PIE,
                name="Investment Amount",
                hole=0.4,
                textinfo="label+percent",
                textfont=Font(color="white"),
                marker=PlotDataMarker(color="#72C8A9")
            )
        ]
    end
end

# Helper function to update investor metrics
function update_investor_metrics(investors, monthly_profit)
    if !isempty(investors)
        total_investment = sum(i.amount for i in investors)
        for investor in investors
            investor.equity = (investor.amount / total_investment) * 100
            investor.monthly_profit = monthly_profit * (investor.equity / 100)
            (investor.breakeven_years, investor.breakeven_months, investor.breakeven_days) = 
                calculate_breakeven(investor.amount, investor.monthly_profit)
        end
    end
    return investors
end

# Helper function to update property values
function calculate_property_values(land_cost, annual_appreciation)
    year1 = calculate_future_value(land_cost, annual_appreciation, 1)
    year3 = calculate_future_value(land_cost, annual_appreciation, 3)
    year5 = calculate_future_value(land_cost, annual_appreciation, 5)
    year10 = calculate_future_value(land_cost, annual_appreciation, 10)
    values = [land_cost, year1, year3, year5, year10]
    
    return (year1, year3, year5, year10, values)
end

# Helper function to calculate monthly revenue
function calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
    return num_rooms * nightly_rate * occupancy_rate * 30
end

# Helper function to update operating costs and related metrics
function update_operating_costs(operating_costs)
    return sum(cost.amount for cost in operating_costs)
end

# Helper function to calculate horse revenue
function calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
    return monthly_treks * people_per_trek * cost_per_person
end

# Update the financial calculations helper
function calculate_financials(num_rooms, nightly_rate, occupancy_rate, monthly_treks, people_per_trek, cost_per_person, operating_costs)
    lodging_revenue = calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
    horse_revenue = calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
    total_revenue = lodging_revenue + horse_revenue
    
    operating_costs_total = update_operating_costs(operating_costs)
    monthly_profit = total_revenue - operating_costs_total
    
    return (total_revenue, operating_costs_total, monthly_profit)
end

# Update all metrics and charts
function update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
    # Update financial values
    financial_values = [monthly_revenue, monthly_operating_costs, monthly_profit]
    
    # Update investor metrics
    investors = update_investor_metrics(investors, monthly_profit)
    investment_plot = update_plot(investors, monthly_profit)
    
    return (financial_values, investors, investment_plot)
end

@app begin
    @in land_cost = 800000.0
    @in num_rooms::Int = 6
    @in nightly_rate::Float64 = 90.0
    @in occupancy_rate::Float64 = 0.6
    @in monthly_operating_costs::Float64 = 2000.0
    @in annual_appreciation = 3.0
    
    # Investment Structure
    @out investors = Investor[]
    @in add_investor = false
    @in remove_investor = false
    @in new_investor_name = ""
    @in new_investor_amount = 0.0
    
    # Financial Overview
    @out monthly_revenue::Float64 = 0.0
    @out monthly_profit::Float64 = 0.0
    @out investor1_monthly_profit = 0.0
    @out investor2_monthly_profit = 0.0
    
    # Property Value Projections
    @out year1_value = 0.0
    @out year3_value = 0.0
    @out year5_value = 0.0
    @out year10_value = 0.0
    @out years::Vector{Int} = [0, 1, 3, 5, 10]
    @out values::Vector{Float64} = [0.0, 0.0, 0.0, 0.0, 0.0]
    
    # Chart data
    @out investment_plot = [
        PlotData(
            labels=["No Investment"],
            values=[100],
            plot=StipplePlotly.Charts.PLOT_TYPE_PIE,
            name="Investment Amount",
            hole=0.4,
            textinfo="label+percent",
            textfont=Font(color="white"),
            marker=PlotDataMarker(color="#72C8A9")
        )
    ]
    @out investment_layout = PlotLayout(
        title=PlotLayoutTitle(text="Investment Distribution"),
        showlegend=false,
        height=400
    )

    # Property value chart configuration
    @out property_chart_data = [Dict(
        "x" => years,
        "y" => values,
        "mode" => "lines+markers",
        "type" => "scatter",
        "name" => "Property Value",
        "line" => Dict("color" => "rgb(61, 185, 100)", "width" => 2),
        "marker" => Dict("size" => 8)
    )]

    @out property_chart_layout = Dict(
        "title" => "Property Value Over Time",
        "xaxis" => Dict("title" => "Years", "range" => [0, 10]),
        "yaxis" => Dict("title" => "Value"),
        "height" => 400
    )

    # Operating Costs Structure
    @out operating_costs = OperatingCost[]
    @in add_cost = false
    @in remove_cost = false
    @in new_cost_name = ""
    @in new_cost_amount = 0.0

    # Financial metrics for charts
    @out financial_labels = ["Revenue", "Operating Costs", "Net Profit"]
    @out financial_values = [0.0, 0.0, 0.0]
    @out financial_colors = ["rgb(61, 185, 100)", "rgb(201, 90, 218)", "rgb(54, 162, 235)"]

    # Horse Operations
    @in monthly_treks::Int = 4
    @in people_per_trek::Int = 5
    @in cost_per_person::Float64 = 80.0
    
    # Tab navigation
    @in activeTab::String = "setup"  # Default to setup tab

    # Initialize when page loads
    @onchange isready begin
        # Initialize default investors
        investors = [
            Investor(name="Mulligan", amount=610000.0),
            Investor(name="Pat", amount=100000.0),
            Investor(name="Colleen", amount=40000.0),
            Investor(name="Charlie", amount=50000.0)
        ]

        # Initialize operating costs with mock data
        operating_costs = [
            OperatingCost(name="Property Management", amount=1000.0),
            OperatingCost(name="Maintenance", amount=500.0),
            OperatingCost(name="Utilities", amount=600.0),
            OperatingCost(name="Insurance", amount=200.0),
            OperatingCost(name="Property Tax", amount=200.0)
        ]

        # Calculate initial metrics
        (monthly_revenue, monthly_operating_costs, monthly_profit) = 
            calculate_financials(num_rooms, nightly_rate, occupancy_rate, monthly_treks, people_per_trek, cost_per_person, operating_costs)
        (financial_values, investors, investment_plot) = 
            update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
        
        # Initialize property values
        (year1_value, year3_value, year5_value, year10_value, values) = 
            calculate_property_values(land_cost, annual_appreciation)
            
        # Update chart data
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

    # Update financial metrics when input parameters change
    @onchange num_rooms, nightly_rate, occupancy_rate, monthly_treks, people_per_trek, cost_per_person begin
        (monthly_revenue, monthly_operating_costs, monthly_profit) = 
            calculate_financials(num_rooms, nightly_rate, occupancy_rate, 
                               monthly_treks, people_per_trek, cost_per_person, 
                               operating_costs)
        (financial_values, investors, investment_plot) = 
            update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
    end

    # Update when property values change
    @onchange land_cost, annual_appreciation begin
        (year1_value, year3_value, year5_value, year10_value, values) = 
            calculate_property_values(land_cost, annual_appreciation)
            
        # Update chart data
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

    # Button handlers
    @onbutton add_investor begin
        if !isempty(new_investor_name) && new_investor_amount > 0
            push!(investors, Investor(
                name=new_investor_name,
                amount=new_investor_amount
            ))
            
            new_investor_name = ""
            new_investor_amount = 0.0
            
            # Update all metrics
            investors = update_investor_metrics(investors, monthly_profit)
            investment_plot = update_plot(investors, monthly_profit)
        end
    end

    @onbutton remove_investor begin
        if length(investors) > 0
            new_investors = copy(investors)  # Create a copy
            deleteat!(new_investors, length(new_investors))
            investors = new_investors  # Assign the new copy
            
            # Update all metrics
            investors = update_investor_metrics(investors, monthly_profit)
            investment_plot = update_plot(investors, monthly_profit)
        end
        remove_investor = false
    end

    # Button handlers for costs
    @onbutton add_cost begin
        if !isempty(new_cost_name) && new_cost_amount > 0
            push!(operating_costs, OperatingCost(
                name=new_cost_name,
                amount=new_cost_amount
            ))
            
            new_cost_name = ""
            new_cost_amount = 0.0
            
            # Update all metrics
            (monthly_revenue, monthly_operating_costs, monthly_profit) = 
                calculate_financials(num_rooms, nightly_rate, occupancy_rate,
                                   monthly_treks, people_per_trek, cost_per_person,
                                   operating_costs)
            (financial_values, investors, investment_plot) = 
                update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
        end
    end

    @onbutton remove_cost begin
        if length(operating_costs) > 0
            new_costs = copy(operating_costs)
            deleteat!(new_costs, length(new_costs))
            operating_costs = new_costs
            
            # Update all metrics
            (monthly_revenue, monthly_operating_costs, monthly_profit) = 
                calculate_financials(num_rooms, nightly_rate, occupancy_rate,
                                   monthly_treks, people_per_trek, cost_per_person,
                                   operating_costs)
            (financial_values, investors, investment_plot) = 
                update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
        end
        remove_cost = false
    end
end

@page("/", "app.jl.html")

end
