class CreateRecords < ActiveRecord::Migration[5.1]
  def change
    create_table :records do |t|
      # Bigint gives 64 bits. For scores, this covers even Giga Wing 2,
      # assuming we 'abuse' negative numbers to double the range.
      # Times can be represented like: 1'20"865 -> 80865
      t.bigint :value, null: false
      # This is optional, meant to be used for cases when the submission
      # (creation) time differs significantly from the time the record was
      # actually achieved.
      t.datetime :achieved_at

      t.references :chart, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
