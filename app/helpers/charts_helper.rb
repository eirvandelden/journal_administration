# Helpers for rendering inline server-side SVG charts.
module ChartsHelper
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
end
