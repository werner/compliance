class EventLog < ApplicationRecord
  include StaticModels::BelongsTo
  belongs_to :admin_user, optional: true
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :verb, class_name: 'EventLogKind'  
end
