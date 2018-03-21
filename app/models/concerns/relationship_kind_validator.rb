class RelationshipKindValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if RelationshipKind.find(value.to_s).nil?
      record.errors.add(:kind, "kind not found")
    end
  end
end
