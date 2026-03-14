module PdfAttachmentValidatable
  extend ActiveSupport::Concern

  PDF_CONTENT_TYPE = "application/pdf".freeze

  class_methods do
    def validates_pdf_attachment_of(*names)
      names.each do |name|
        validate do
          attachment = public_send(name)

          next unless attachment.attached?
          next if attachment.content_type == PDF_CONTENT_TYPE

          errors.add(name, :must_be_pdf)
        end
      end
    end
  end
end
