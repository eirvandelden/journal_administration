module ProductsHelper
  CHART_WIDTH = 600
  CHART_HEIGHT = 200

  # Turns prices into the points of an SVG polyline, scaled from zero so a
  # bonus reads as a dip rather than a loss
  def price_chart_points(prices, highest)
    return "" if prices.size < 2 || highest.to_d.zero?

    step = CHART_WIDTH.to_d / (prices.size - 1)
    prices.each_with_index.map { |price, index| "#{(index * step).round(1)},#{chart_y(price, highest)}" }.join(" ")
  end

  private

  def chart_y(price, highest)
    (CHART_HEIGHT - (price / highest * CHART_HEIGHT)).round(1)
  end
end
