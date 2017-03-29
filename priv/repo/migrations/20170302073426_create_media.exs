defmodule CaptainFact.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:medias) do
      add :name, :string, null: false
      add :url_pattern, :string

      timestamps()
    end

  end
end