module FinancialFormulas

export calculate_monthly_revenue,
       calculate_horse_revenue,
       update_operating_costs,
       calculate_property_values,
       update_all_metrics,
       calculate_breakeven

# Helper function to calculate monthly revenue from lodging
function calculate_monthly_revenue(num_rooms, nightly_rate, occupancy_rate)
    return num_rooms * nightly_rate * occupancy_rate * 30
end

# Helper function to calculate horse revenue
function calculate_horse_revenue(monthly_treks, people_per_trek, cost_per_person)
    return monthly_treks * people_per_trek * cost_per_person
end

# Helper function to calculate total operating costs
function update_operating_costs(operating_costs)
    return sum(cost.amount for cost in operating_costs)
end

# Helper function to calculate property values over time
function calculate_property_values(initial_value, annual_appreciation)
    years = [0, 1, 3, 5, 10]
    values = Float64[]
    
    for year in years
        value = initial_value * (1 + annual_appreciation/100)^year
        push!(values, value)
    end
    
    year1_value = initial_value * (1 + annual_appreciation/100)^1
    year3_value = initial_value * (1 + annual_appreciation/100)^3
    year5_value = initial_value * (1 + annual_appreciation/100)^5
    year10_value = initial_value * (1 + annual_appreciation/100)^10
    
    return (year1_value, year3_value, year5_value, year10_value, values)
end

# Helper function to calculate breakeven time
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

# Helper function to update all financial metrics
function update_all_metrics(monthly_revenue, monthly_operating_costs, monthly_profit, investors)
    # Update financial values array
    financial_values = [monthly_revenue, monthly_operating_costs, monthly_profit]
    
    # Update investor metrics
    if !isempty(investors)
        total_investment = sum(investor.amount for investor in investors)
        for investor in investors
            investor.equity = (investor.amount / total_investment) * 100
            investor.monthly_profit = monthly_profit * (investor.equity / 100)
            
            # Calculate break-even time
            (investor.breakeven_years, investor.breakeven_months, investor.breakeven_days) = 
                calculate_breakeven(investor.amount, investor.monthly_profit)
        end
    end
    
    # Update investment plot
    if isempty(investors)
        investment_plot = [Dict(
            "labels" => ["No Investment"],
            "values" => [100],
            "type" => "pie",
            "name" => "Investment Amount",
            "hole" => 0.4,
            "textinfo" => "label+percent",
            "textfont" => Dict("color" => "white"),
            "marker" => Dict("colors" => ["#72C8A9"])
        )]
    else
        investment_plot = [Dict(
            "labels" => [i.name for i in investors],
            "values" => [i.amount for i in investors],
            "type" => "pie",
            "name" => "Investment Amount",
            "hole" => 0.4,
            "textinfo" => "label+percent",
            "textfont" => Dict("color" => "white"),
            "marker" => Dict(
                "colors" => ["#72C8A9", "#BD5631", "#54A2EB", "#FF9F40", "#9966FF"]
            )
        )]
    end
    
    return (financial_values, investors, investment_plot)
end

end 