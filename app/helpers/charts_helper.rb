# Helpers for rendering inline server-side SVG charts.
module ChartsHelper
  include BudgetHelper

  # @api private
  BAR_CHART_DIMS = { width: 640, height: 320, pad_left: 70, pad_top: 30, pad_bottom: 40 }.freeze

  # @api private
  DONUT_COLORS = [
    "oklch(64% 0.15 145)",
    "oklch(60% 0.15 250)",
    "oklch(75% 0.15 85)",
    "oklch(60% 0.15 25)"
  ].freeze

  # @api private
  DONUT_GEOMETRY = { cx: 100, cy: 100, r: 80, inner_r: 45 }.freeze

  # Renders an inline SVG donut chart with a legend.
  #
  # @param labels [Array<String>] slice labels
  # @param data [Array<Numeric>] values per slice
  # @param colors [Array<String>, nil] CSS color values; defaults to DONUT_COLORS
  # @return [String] HTML-safe SVG markup
  def svg_donut_chart(labels:, data:, colors: nil)
    colors ||= DONUT_COLORS
    total = data.sum.to_f
    return content_tag(:p, "") if total.zero?

    slices = build_donut_slices(labels, data, total, colors)
    legend = build_donut_legend(labels, data, colors)
    content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 320 200", role: "img") do
      safe_join(slices + legend)
    end
  end

  # @api private
  BUDGET_CHART_DIMS = { width: 500, row_height: 32, label_width: 130, pad_right: 20, pad_top: 10 }.freeze

  # @api private
  BUDGET_STATUS_COLORS = {
    green:  "var(--color-green, oklch(64% 0.15 145))",
    orange: "var(--color-orange, oklch(70% 0.15 60))",
    red:    "var(--color-red, oklch(60% 0.15 25))",
    grey:   "var(--color-grey, #888888)"
  }.freeze

  # Renders an inline SVG horizontal budget vs. actual bar chart.
  #
  # Shows credit categories (spending limits) and debit categories (savings targets)
  # color-coded by status. Returns an empty paragraph when no budget is given.
  #
  # @param budget [Budget, nil] the active budget
  # @param debit_transactions [Hash{Category => Numeric}] actual debit amounts
  # @param credit_transactions [Hash{Category => Numeric}] actual credit amounts
  # @return [String] HTML-safe SVG markup
  def svg_budget_chart(budget:, debit_transactions:, credit_transactions:)
    return content_tag(:p, "") unless budget

    budget_by_cat = budget.budget_categories
                          .includes(:category)
                          .each_with_object({}) { |bc, h| h[bc.category] = bc.amount }

    credit_rows = build_budget_rows(credit_transactions, budget_by_cat, :credit)
    debit_rows  = build_budget_rows(debit_transactions,  budget_by_cat, :debit)
    all_rows    = credit_rows + debit_rows

    return content_tag(:p, "") if all_rows.empty?

    d      = BUDGET_CHART_DIMS
    height = d[:pad_top] + all_rows.size * d[:row_height] + d[:pad_top]
    max_amount = all_rows.map { |r| [ r[:actual], r[:budgeted] || 0 ].max }.max.to_f
    bar_width  = d[:width] - d[:label_width] - d[:pad_right]

    content_tag(:svg,
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 #{d[:width]} #{height}",
                role: "img") do
      parts = all_rows.each_with_index.map do |row, i|
        budget_chart_row(row, i, max_amount, bar_width, d)
      end
      safe_join(parts)
    end
  end

  # Renders an inline SVG bar chart, optionally with a historical-average reference line.
  #
  # @param labels [Array<String>] category labels
  # @param data [Array<Numeric>] values per label
  # @param reference [Array<Numeric>, nil] reference values for a comparison polyline
  # @param y_label [String, nil] accessible aria-label for the chart
  # @return [String] HTML-safe SVG markup
  def svg_bar_chart(labels:, data:, reference: nil, y_label: nil)
    return content_tag(:p, "") if labels.empty?

    effective_max = [ data.max.to_f, reference&.max.to_f ].compact.max
    config = bar_chart_config(labels.size, effective_max)

    content_tag(:svg, xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 #{config[:width]} #{config[:height]}",
                role: "img", "aria-label": y_label) do
      parts = grid_lines(config)
      parts += labels.each_with_index.map { |label, i| bar_element(label, data[i].to_f, i, config) }
      parts << reference_line(reference, config) if reference
      safe_join(parts)
    end
  end

  private

  def bar_chart_config(bar_count, max)
    d            = BAR_CHART_DIMS
    chart_width  = d[:width] - d[:pad_left] - 20
    chart_height = d[:height] - d[:pad_bottom] - d[:pad_top]
    gap          = (chart_width.to_f / bar_count).round
    d.merge(chart_height: chart_height, bar_width: (chart_width.to_f / bar_count * 0.6).round,
            gap: gap, max: max)
  end

  def grid_lines(config)
    (0..4).map do |i|
      fraction = i.to_f / 4
      value    = (config[:max] * fraction).round
      y        = config[:pad_top] + config[:chart_height] - (fraction * config[:chart_height]).round
      tag.line(x1: config[:pad_left], y1: y, x2: config[:width] - 10, y2: y,
               stroke: "var(--color-border, #ccc)", "stroke-width": "1") +
        tag.text(value.to_s, x: config[:pad_left] - 4, y: y + 4,
                 "text-anchor": "end", "font-size": "10", fill: "currentColor")
    end
  end

  def bar_element(label, value, index, config)
    bar_h = config[:max] > 0 ? (value / config[:max] * config[:chart_height]).round : 0
    bw    = config[:bar_width]
    x     = config[:pad_left] + index * config[:gap] + (config[:gap] - bw) / 2
    y     = config[:pad_top] + config[:chart_height] - bar_h
    tag.rect(x: x, y: y, width: bw, height: bar_h, fill: "var(--color-accent)", rx: 2) +
      bar_axis_label(label, bw, x, config[:height]) +
      bar_value_label(value, bar_h, bw, x, y)
  end

  def bar_axis_label(label, bw, x, height)
    tag.text(label.to_s.truncate(12), x: x + bw / 2, y: height - 8,
             "text-anchor": "middle", "font-size": "11", fill: "currentColor")
  end

  def bar_value_label(value, bar_h, bw, x, y)
    return "".html_safe if bar_h.zero?

    formatted = value == value.to_i ? value.to_i.to_s : ("%.1f" % value)
    tag.text(formatted, x: x + bw / 2, y: y - 4,
             "text-anchor": "middle", "font-size": "11", fill: "currentColor")
  end

  def reference_line(reference, config)
    points = reference.each_with_index.map do |value, i|
      x = config[:pad_left] + i * config[:gap] + config[:gap] / 2
      bar_y = config[:max] > 0 ? (value.to_f / config[:max] * config[:chart_height]).round : 0
      y = config[:pad_top] + config[:chart_height] - bar_y
      [ x, y ]
    end

    polyline_pts = points.map { |x, y| "#{x},#{y}" }.join(" ")
    circles = points.map { |x, y| tag.circle(cx: x, cy: y, r: 3, fill: "var(--color-muted, #888)") }

    tag.polyline(points: polyline_pts, fill: "none", stroke: "var(--color-muted, #888)", "stroke-width": "2") +
      safe_join(circles)
  end

  def build_donut_slices(labels, data, total, colors)
    non_zero = data.each_index.select { |i| data[i].to_f.positive? }
    angle    = -Math::PI / 2
    labels.each_with_index.filter_map do |_label, i|
      next if data[i].to_f.zero?

      slice  = non_zero.one? ? full_ring_slice(i, colors) : arc_slice(data[i].to_f, total, angle, i, colors)
      angle += data[i].to_f / total * 2 * Math::PI
      slice
    end
  end

  def full_ring_slice(index, colors)
    g           = DONUT_GEOMETRY
    ring_radius = g[:inner_r] + (g[:r] - g[:inner_r]) / 2.0
    tag.circle(cx: g[:cx], cy: g[:cy], r: ring_radius, fill: "none",
               stroke: colors[index % colors.size], "stroke-width": g[:r] - g[:inner_r])
  end

  def arc_slice(value, total, angle, index, colors)
    sweep = value / total * 2 * Math::PI
    tag.path(d: arc_path(angle, sweep), fill: colors[index % colors.size])
  end

  def arc_path(angle, sweep)
    g     = DONUT_GEOMETRY
    large = sweep > Math::PI ? 1 : 0
    x1,  y1  = [ g[:cx] + g[:r] * Math.cos(angle),          g[:cy] + g[:r] * Math.sin(angle) ]
    x2,  y2  = [ g[:cx] + g[:r] * Math.cos(angle + sweep),  g[:cy] + g[:r] * Math.sin(angle + sweep) ]
    ix1, iy1 = [ g[:cx] + g[:inner_r] * Math.cos(angle),    g[:cy] + g[:inner_r] * Math.sin(angle) ]
    ix2, iy2 = [ g[:cx] + g[:inner_r] * Math.cos(angle + sweep), g[:cy] + g[:inner_r] * Math.sin(angle + sweep) ]
    "M #{ix1.round(2)},#{iy1.round(2)} L #{x1.round(2)},#{y1.round(2)} " \
      "A #{g[:r]},#{g[:r]} 0 #{large},1 #{x2.round(2)},#{y2.round(2)} " \
      "L #{ix2.round(2)},#{iy2.round(2)} A #{g[:inner_r]},#{g[:inner_r]} 0 #{large},0 #{ix1.round(2)},#{iy1.round(2)} Z"
  end

  def build_donut_legend(labels, data, colors)
    labels.each_with_index.filter_map do |label, i|
      next if data[i].to_f.zero?

      ly = 60 + i * 22
      tag.rect(x: 200, y: ly - 10, width: 12, height: 12, fill: colors[i % colors.size]) +
        tag.text(label.to_s.truncate(18), x: 216, y: ly,
                 "font-size": "12", fill: "currentColor", "dominant-baseline": "auto")
    end
  end

  def build_budget_rows(transactions, budget_by_cat, direction)
    direction_budget = budget_by_cat.select { |cat, _| cat.public_send(:"#{direction}?") }
    all_cats = (transactions.keys + direction_budget.keys).uniq.compact
    all_cats.filter_map do |cat|
      next unless cat

      actual   = transactions[cat].to_f
      budgeted = budget_by_cat[cat]
      { category: cat, actual: actual, budgeted: budgeted }
    end
  end

  def budget_chart_row(row, index, max_amount, bar_width, d)
    category  = row[:category]
    actual    = row[:actual]
    budgeted  = row[:budgeted]
    status    = budget_status(category: category, actual: actual, budgeted: budgeted)
    bar_color = status ? BUDGET_STATUS_COLORS[status] : BUDGET_STATUS_COLORS[:grey]

    y = d[:pad_top] + index * d[:row_height]

    label_el  = budget_chart_label(category.name, y, d[:label_width])
    bg_bar_el = budget_chart_bg_bar(budgeted, max_amount, bar_width, y, d)
    actual_el = budget_chart_actual_bar(actual, max_amount, bar_width, y, d, bar_color)

    safe_join([ label_el, bg_bar_el, actual_el ].compact)
  end

  def budget_chart_label(name, y, label_width)
    tag.text(name.to_s.truncate(16),
             x: label_width - 4,
             y: y + 16,
             "text-anchor": "end",
             "font-size": "11",
             fill: "currentColor")
  end

  def budget_chart_bg_bar(budgeted, max_amount, bar_width, y, d)
    return nil unless budgeted && max_amount > 0

    w = (budgeted.to_f / max_amount * bar_width).round
    tag.rect(x: d[:label_width], y: y + 4, width: w, height: d[:row_height] - 8,
             fill: "var(--color-border, #ddd)", rx: 2)
  end

  def budget_chart_actual_bar(actual, max_amount, bar_width, y, d, color)
    return nil if actual.zero? || max_amount.zero?

    w = (actual / max_amount * bar_width).round
    tag.rect(x: d[:label_width], y: y + 8, width: w, height: d[:row_height] - 16,
             fill: color, rx: 2)
  end
end
