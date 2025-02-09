module FinancialFormulas

export calculate_monthly_revenue,
       calculate_horse_revenue,
       update_operating_costs,
       calculate_property_values,
       update_all_metrics

# Calculate monthly revenue from lodging
function calculate_monthly_revenue(num_rooms::Int, nightly_rate::Float64, occupancy_rate::Float64)
    return num_rooms * nightly_rate * occupancy_rate * 30  # Assuming 30 days per month
end

# Calculate monthly revenue from horse treks
function calculate_horse_revenue(monthly_treks::Int, people_per_trek::Int, cost_per_person::Float64)
    return monthly_treks * people_per_trek * cost_per_person
end

# Update total operating costs
function update_operating_costs(costs::Vector)
    return isempty(costs) ? 0.0 : sum(cost.amount for cost in costs)
end

# Calculate property values over time
function calculate_property_values(initial_value::Float64, annual_appreciation::Float64)
    years = [0, 1, 3, 5, 10]
    values = Float64[]
    
    for year in years
        value = initial_value * (1 + annual_appreciation/100)^year
        push!(values, value)
    end
    
    return (
        values[2],  # year1
        values[3],  # year3
        values[4],  # year5
        values[5],  # year10
        values     # all values
    )
end

# Update financial metrics for all investors
function update_all_metrics(monthly_revenue::Float64, monthly_operating_costs::Float64, monthly_profit::Float64, investors::Vector)
    total_investment = sum(investor.amount for investor in investors)
    
    # Update each investor's metrics
    for investor in investors
        if total_investment > 0
            investor.equity = (investor.amount / total_investment) * 100  # Convert to percentage
            investor.monthly_profit = monthly_profit * (investor.equity / 100)  # Convert back to decimal for profit calc
            
            # Calculate breakeven
            if investor.monthly_profit > 0
                months_to_breakeven = ceil(investor.amount / investor.monthly_profit)
                investor.breakeven_years = Int(floor(months_to_breakeven / 12))
                investor.breakeven_months = Int(floor(months_to_breakeven % 12))
                investor.breakeven_days = Int(floor((months_to_breakeven % 1) * 30))
            end
        end
    end
    
    # Create investment plot data
    investment_plot = [Dict(
        "labels" => [inv.name for inv in investors],
        "values" => [inv.amount for inv in investors],
        "type" => "pie"
    )]
    
    financial_values = [monthly_revenue, monthly_operating_costs, monthly_profit]
    
    return (financial_values, investors, investment_plot)
end

end # module 
