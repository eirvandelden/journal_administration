require "test_helper"

class FormLabelsTest < ActionDispatch::IntegrationTest
  LABELS = {
    nl: {
      transaction: [ "ID", "Debiteur", "Crediteur", "Categorie", "Opmerking", "Boekingsdatum", "Rentedatum", "Type",
                     "Oorspronkelijke omschrijving", "Oorspronkelijk saldo na mutatie", "Oorspronkelijk label" ],
      category: [ "Richting", "Hoofdcategorie" ],
      chattel: [ "Aankooptransactie" ]
    },
    it: {
      transaction: [ "ID", "Debitore", "Creditore", "Categoria", "Nota", "Data registrazione", "Data valuta", "Tipo",
                     "Descrizione originale", "Saldo originale dopo il movimento", "Etichetta originale" ],
      category: [ "Direzione", "Categoria principale" ],
      chattel: [ "Transazione d'acquisto" ]
    }
  }.freeze

  PAGES = {
    transaction: -> { edit_transaction_path(transactions(:debit_grocery)) },
    category: -> { edit_category_path(categories(:groceries)) },
    chattel: -> { edit_chattel_path(chattels(:one)) }
  }.freeze

  setup do
    @user = users(:admin)
  end

  LABELS.each_key do |locale|
    names = { nl: "Dutch", it: "Italian" }.fetch(locale)

    test "the transaction form labels its fields in #{names}" do
      assert_labels locale, :transaction
    end

    test "the category form labels direction and parent category in #{names}" do
      assert_labels locale, :category
    end

    test "the chattel form labels the purchase transaction in #{names}" do
      assert_labels locale, :chattel
    end
  end

  private

  def assert_labels(locale, form)
    @user.update!(locale: locale)
    sign_in_as(@user)

    get instance_exec(&PAGES.fetch(form))

    assert_response :success
    LABELS.dig(locale, form).each do |text|
      assert_select "form label", text: text
    end
  end
end
