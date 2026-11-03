# Aceita apenas PDF de até 10 MB no anexo validado. O tipo vem do conteúdo do
# arquivo (Active Storage identifica), não da extensão.
class PdfAttachmentValidator < ActiveModel::EachValidator
  MAX_SIZE = 10.megabytes

  def validate_each(record, attribute, attachment)
    return unless attachment.attached? && record.attachment_changes[attribute.to_s]

    label = options.fetch(:label)
    record.errors.add(:base, "#{label} precisa ser um arquivo PDF") unless attachment.content_type == "application/pdf"
    record.errors.add(:base, "#{label} precisa ter no máximo 10 MB") if attachment.byte_size > MAX_SIZE
  end
end
