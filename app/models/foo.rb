class Foo < ApplicationRecord
  belongs_to :foo, class_name: "Transaction", foreign_key: "foo_id" # Transaction is a keyword # TODO: this is parent
  belongs_to :bar, class_name: "Transaction", foreign_key: "bar_id" # TODO: this is the related transaction
end
