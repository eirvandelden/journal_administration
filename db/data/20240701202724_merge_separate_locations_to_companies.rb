# frozen_string_literal: true

class MergeSeparateLocationsToCompanies < ActiveRecord::Migration[7.1]
  def up
    # AH
    albert_heijns = Account.all.select { |account|
                      account.name =~ /AH to go|AH |.*(Albert Heijn|ALBERT HEIJN|AH to go)/ }
    target        = Account.find_or_create_by name: "Albert Heijn B.V."

    albert_heijns.each do |ah|
      Transaction.where(debitor_account_id: ah.id).update_all(debitor_account_id: target.id)
      Transaction.where(creditor_account_id: ah.id).update_all(creditor_account_id: target.id)
    end
    albert_heijns = albert_heijns - [ target ]
    albert_heijns.map(&:destroy)

    # Jumbo
    jumbos = Account.all.select { |account| account.name =~ /Jumbo / }
    target = Account.find_or_create_by name: "Jumbo B.V."
    jumbos.each do |jumbo|
      Transaction.where(debitor_account_id: jumbo.id).update_all(debitor_account_id: target.id)
      Transaction.where(creditor_account_id: jumbo.id).update_all(creditor_account_id: target.id)
    end

    jumbos = jumbos - [ target ]
    jumbos.map(&:destroy)

    # Kruidvat
    kruidvaten = Account.all.select { |account| account.name =~ /Jumbo / }
    target     = Account.find_or_create_by name: "Kruidvat B.V."
    kruidvaten.each do |kruidvat|
      Transaction.where(debitor_account_id: kruidvat.id).update_all(debitor_account_id: target.id)
      Transaction.where(creditor_account_id: kruidvat.id).update_all(creditor_account_id: target.id)
    end

    kruidvat = kruidvat - [ target ]
    kruidvat.map(&:destroy)
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
