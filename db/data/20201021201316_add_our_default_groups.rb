class AddOurDefaultGroups < ActiveRecord::Migration[6.0]
  def up
    [
      { name: "Boodschappen, huishoudelijk en persoonlijke verzorg", account: "K29925258" },
      { name: "Vrije tijd en hobby", account: "R29925201" },
      { name: "Auto en vervoer", account: "S29925205" },
      { name: "Serena, kapper en kleding", account: "T29925196" },
      { name: "Cadeautjes en speelgoed", account: "W29925250" },
      { name: "Projecten", account: "L29925232" },
      { name: "Extraatjes", account: "S29925222" },
      { name: "Reserveringen", account: "D29925285" },
      { name: "Vakantie", account: "L29925215" },
      { name: "Buffer", account: "D29925166" },
      { name: "Vaste lasten", account: "" },
      { name: "Technisch", account: "" }
    ].each do |values|
      if values[:account].blank?
        CategoryGroup.create name: values[:name]
      else
        CategoryGroup.create name: values[:name], account: Account.find_by(account_number: values[:account])
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
