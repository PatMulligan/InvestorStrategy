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

@app begin
    # Reactive variables first
    @in darkmode = true
    @out dark = true
    
    @in land_cost = 780000.0
    @in num_rooms = 10
    @in nightly_rate = 90.0
    @in occupancy_rate = 0.7
    @in monthly_operating_costs = 15000.0
    @in annual_appreciation = 3.0
    
    # Investment Structure
    @out investors = [(name="Investor 1", amount=390000.0),
                     (name="Investor 2", amount=390000.0)]
    @in new_investor_name::String = ""
    @in new_investor_amount::Float64 = 0.0
    @in add_investor = false
    @in remove_investor = false
    
    # Other output variables
    @out equity_labels = ["Investor 1", "Investor 2"]
    @out equity_values = [50.0, 50.0]
    @out financial_labels = ["Revenue", "Operating Costs", "Net Profit"]
    @out financial_values = [0.0, 0.0, 0.0]
    @out financial_colors = ["rgb(61, 185, 100)", "rgb(201, 90, 218)", "rgb(54, 162, 235)"]
    
    # Financial Overview
    @out monthly_revenue = 0.0
    @out monthly_profit = 0.0
    @out investor1_monthly_profit = 0.0
    @out investor2_monthly_profit = 0.0
    
    # Property Value Projections
    @out year1_value = 0.0
    @out year3_value = 0.0
    @out year5_value = 0.0
    @out year10_value = 0.0
    
    # Break-even times
    @out investor1_breakeven_years = 0
    @out investor1_breakeven_months = 0
    @out investor1_breakeven_days = 0
    @out investor2_breakeven_years = 0
    @out investor2_breakeven_months = 0
    @out investor2_breakeven_days = 0
    
    # Initialize equity variables
    @out investor1_equity = 0.0
    @out investor2_equity = 0.0

    # Chart data
    @out investment_plot = PlotData[]
    @out investment_layout = PlotLayout(
        title=PlotLayoutTitle(text="Investment Distribution"),
        showlegend=true,  # Show legend for pie chart
        height=300
    )

    # Button handlers
    @onbutton add_investor begin
        if !isempty(new_investor_name) && new_investor_amount > 0
            new_investors = copy(investors)  # Create a copy
            push!(new_investors, (name=new_investor_name, amount=new_investor_amount))
            investors = new_investors  # Assign the new copy
            new_investor_name = ""
            new_investor_amount = 0.0
        end
        add_investor = false
    end

    @onbutton remove_investor begin
        if length(investors) > 0
            new_investors = copy(investors)  # Create a copy
            deleteat!(new_investors, length(new_investors))
            investors = new_investors  # Assign the new copy
        end
        remove_investor = false
    end

    # Reactive updates
    @onchange darkmode begin
        dark = darkmode
    end

    @onchange investors begin
        # Update chart
        if !isempty(investors)
            total_investment = sum(i.amount for i in investors)
            investment_plot = [
                PlotData(
                    labels=[i.name for i in investors],
                    values=[i.amount for i in investors],
                    plot=StipplePlotly.Charts.PLOT_TYPE_PIE,  # Change to pie
                    name="Investment Amount",
                    hole=0.4,  # Creates a donut chart
                    textinfo="label+percent",
                    marker=PlotDataMarker(
                        colors=["#72C8A9", "#BD5631", "#54A2EB", "#FF9F40", "#9966FF"]
                    )
                )
            ]

            # Update equity calculations
            if length(investors) >= 2
                investor1_equity = (investors[1].amount / total_investment) * 100
                investor2_equity = (investors[2].amount / total_investment) * 100
            else
                investor1_equity = 0.0
                investor2_equity = 0.0
            end
        else
            investment_plot = [
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
            investor1_equity = 0.0
            investor2_equity = 0.0
        end

        # Update financial metrics
        monthly_revenue = num_rooms * nightly_rate * occupancy_rate * 30
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        # Calculate future values
        year1_value = calculate_future_value(land_cost, annual_appreciation, 1)
        year3_value = calculate_future_value(land_cost, annual_appreciation, 3)
        year5_value = calculate_future_value(land_cost, annual_appreciation, 5)
        year10_value = calculate_future_value(land_cost, annual_appreciation, 10)
        values = [calculate_future_value(land_cost, annual_appreciation, y) for y in 0:10]
        
        financial_values = [
            monthly_revenue,
            monthly_operating_costs,
            monthly_profit
        ]
    end
end

@page("/", "app.jl.html")

end
