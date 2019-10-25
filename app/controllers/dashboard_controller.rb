class DashboardController < ApplicationController
  def index
    daterange = case params[:filter]
      when 'last_month'
        Time.current.last_month.beginning_of_month..Time.current.last_month.end_of_month
      when 'three_months'
        Time.current.months_ago(3).beginning_of_month..Time.current.last_month.end_of_month
      when 'year_to_date'
        Time.current.beginning_of_year..Time.current.end_of_year
      when 'last_year'
        Time.current.last_year.beginning_of_year..Time.current.last_year.end_of_year
      else
        Time.current.beginning_of_month..Time.current.end_of_month
      end
    transfer_category_id = Category.find_by(name: 'Transfer').id
    @debit_transactions = Debit.where(booked_at: daterange).where.not(category_id: transfer_category_id).group(:category).sum(:amount).sort_by { |k, _v| k&.name || '' }.to_h
    @credit_transactions = Credit.where(booked_at: daterange).where.not(category_id: transfer_category_id).group(:category).sum(:amount).sort_by { |k, _v| k&.name || '' }.to_h

    @debit_total = @debit_transactions.values.sum
    credit_sub_total = @credit_transactions.values.sum
    @profit_or_loss = @debit_total - credit_sub_total
    @credit_total = credit_sub_total + @profit_or_loss
  end
end
