class DashboardController < ApplicationController
  def index
    daterange = case params[:filter]
    when "last_month"
                  Time.current.last_month.beginning_of_month..Time.current.last_month.end_of_month
    when "three_months"
                  Time.current.months_ago(3).beginning_of_month..Time.current.last_month.end_of_month
    when "year_to_date"
                  Time.current.beginning_of_year..Time.current.end_of_year
    when "last_year"
                  Time.current.last_year.beginning_of_year..Time.current.last_year.end_of_year
    else
                  Time.current.beginning_of_month..Time.current.end_of_month
    end

    transfer_category_id      = Category.find_by(name: "Transfer")&.id
    debit_transactions_scope  = Debit.where(debitor_account_id: 7)
                                     .where(booked_at: daterange)

    @debit_transactions       = debit_transactions_scope.where.not(category_id: transfer_category_id)
                                                        .or(debit_transactions_scope.where(category_id: nil))
                                                        .group(:category)
                                                        .sum(:amount)
                                                        .sort_by { |k, _v| k&.name || "" }.to_h

    credit_transactions_scope = Credit.where(creditor_account_id: 7)
                                      .where(booked_at: daterange)

    @credit_transactions      = credit_transactions_scope.where.not(category_id: transfer_category_id)
                                                         .or(credit_transactions_scope.where(category_id: nil))
                                                         .group(:category)
                                                         .sum(:amount)
                                                         .sort_by { |k, _v| k&.name || "" }.to_h

    @debit_total              = @debit_transactions.values.sum
    credit_sub_total          = @credit_transactions.values.sum
    @profit_or_loss           = @debit_total - credit_sub_total
    @credit_total             = credit_sub_total + @profit_or_loss
  end
end
