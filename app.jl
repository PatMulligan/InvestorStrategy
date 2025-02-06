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

@app begin

    # Reactive variables
    @in darkmode = true
    @out dark = true
    
    @in land_cost = 780000.0
    @in num_rooms::Int = 3
    @in nightly_rate::Float64 = 210.0
    @in occupancy_rate::Float64 = 0.9
    @in monthly_operating_costs::Float64 = 2000.0
    @in annual_appreciation = 3.0
    
    # Investment Structure
    @out investors = Investor[]
    @in add_investor = false
    @in remove_investor = false
    @in new_investor_name = ""
    @in new_investor_amount = 0.0
    
    # Other output variables
    @out equity_labels = ["Investor 1", "Investor 2"]
    @out equity_values = [50.0, 50.0]
    @out financial_labels = ["Revenue", "Operating Costs", "Net Profit"]
    @out financial_values = [0.0, 0.0, 0.0]
    @out financial_colors = ["rgb(61, 185, 100)", "rgb(201, 90, 218)", "rgb(54, 162, 235)"]
    
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
    
    # Chart data
    @out investment_plot = [
        PlotData(
            labels=["No Investment"],
            values=[100],
            plot=StipplePlotly.Charts.PLOT_TYPE_PIE,
            name="Investment Amount",
            hole=0.4,
            textinfo="label+percent",
            marker=PlotDataMarker(color="#72C8A9")
        )
    ]
    @out investment_layout = PlotLayout(
        title=PlotLayoutTitle(text="Investment Distribution"),
        showlegend=true,
        height=300
    )

    # Update financial metrics
    @onchange num_rooms, nightly_rate, occupancy_rate, monthly_operating_costs begin
        monthly_revenue = num_rooms * nightly_rate * occupancy_rate * 30
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        # Update investor metrics
        investors = update_investor_metrics(investors, monthly_profit)
        investment_plot = update_plot(investors, monthly_profit)
        
        # Update financial breakdown chart
        financial_values = [monthly_revenue, monthly_operating_costs, monthly_profit]
    end

    # Initialize when page loads
    @onchange isready begin
        monthly_revenue = num_rooms * nightly_rate * occupancy_rate * 30
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        # Update investor metrics
        investors = update_investor_metrics(investors, monthly_profit)
        investment_plot = update_plot(investors, monthly_profit)
        
        # Initialize financial breakdown chart
        financial_values = [monthly_revenue, monthly_operating_costs, monthly_profit]
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

    # Reactive updates
    @onchange darkmode begin
        dark = darkmode
    end
end

@page("/", "app.jl.html")

end
