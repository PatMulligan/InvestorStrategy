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
    # Project Parameters
    @in land_cost = 780000.0
    @in num_rooms = 10
    @in nightly_rate = 90.0
    @in occupancy_rate = 0.7
    @in monthly_operating_costs = 15000.0
    @in annual_appreciation = 3.0  # Property value appreciation rate (%)
    
    # Investment Structure
    @in investor1_amount = 390000.0  # First investor
    @in investor2_amount = 390000.0  # Second investor
    
    # Calculated Equity Shares
    @out investor1_equity = 0.0
    @out investor2_equity = 0.0
    
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
    
    # Add data for property value chart
    @out years = collect(0:10)  # X-axis: years 0 through 10
    @out values = [calculate_future_value(780000, 3.0, y) for y in 0:10]  # Y-axis: property values

    # Add data for equity pie chart
    @out equity_labels = ["Investor 1", "Investor 2"]
    @out equity_values = [50.0, 50.0]  # Default to 50-50 split

    @onchange num_rooms, nightly_rate, occupancy_rate, monthly_operating_costs, 
              investor1_amount, investor2_amount, land_cost, annual_appreciation begin
        # Calculate monthly revenue and profit
        monthly_revenue = num_rooms * nightly_rate * 30 * occupancy_rate
        monthly_profit = monthly_revenue - monthly_operating_costs
        
        # Calculate equity shares for investors
        total_investment = investor1_amount + investor2_amount
        
        if total_investment > 0
            investor1_equity = (investor1_amount / total_investment) * 100
            investor2_equity = (investor2_amount / total_investment) * 100
            
            # Calculate profit shares
            investor1_monthly_profit = monthly_profit * (investor1_equity / 100)
            investor2_monthly_profit = monthly_profit * (investor2_equity / 100)
            
            # Calculate break-even times
            (investor1_breakeven_years, investor1_breakeven_months, investor1_breakeven_days) = 
                calculate_breakeven(investor1_amount, investor1_monthly_profit)
            
            (investor2_breakeven_years, investor2_breakeven_months, investor2_breakeven_days) = 
                calculate_breakeven(investor2_amount, investor2_monthly_profit)
        else
            investor1_equity = 0.0
            investor2_equity = 0.0
            investor1_monthly_profit = 0.0
            investor2_monthly_profit = 0.0
            investor1_breakeven_years, investor1_breakeven_months, investor1_breakeven_days = 999999, 0, 0
            investor2_breakeven_years, investor2_breakeven_months, investor2_breakeven_days = 999999, 0, 0
        end
        
        # Calculate future property values
        year1_value = calculate_future_value(land_cost, annual_appreciation, 1)
        year3_value = calculate_future_value(land_cost, annual_appreciation, 3)
        year5_value = calculate_future_value(land_cost, annual_appreciation, 5)
        year10_value = calculate_future_value(land_cost, annual_appreciation, 10)

        # Update property value chart data
        values = [calculate_future_value(land_cost, annual_appreciation, y) for y in 0:10]

        # Update equity pie chart data
        if total_investment > 0
            equity_values = [investor1_equity, investor2_equity]
        else
            equity_values = [0.0, 0.0]
        end
    end
end

@page("/", "app.jl.html")

end
