module ApplicationHelper
  include Pagy::Frontend

  def qr_code_image(url)
    tag.div url, class: "qr-code"
  end

  def button_to_copy_to_clipboard(url, &block)
    tag.button capture(&block), class: "btn", data: { action: "clipboard#copy", clipboard_text_value: url }
  end

  def web_share_button(url, title, text, &block)
    tag.button capture(&block), class: "btn", data: { action: "web-share#share", web_share_url_value: url, web_share_title_value: title, web_share_text_value: text }
  end
end
