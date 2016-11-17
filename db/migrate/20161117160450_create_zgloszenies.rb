class CreateZgloszenies < ActiveRecord::Migration[5.0]
  def change
    create_table :zgloszenies do |t|
      t.references :klient, foreign_key: true
      t.references :pracownik, foreign_key: true
      t.references :dzial, foreign_key: true
      t.integer :priorytet
      t.integer :status
      t.date :data_zgloszenia
      t.date :data_naprawy
      t.text :opis_uszkodzenia
      t.text :nazwa_urzadzenia
      t.integer :wysylka

      t.timestamps
    end
  end
end
