defmodule CaptainFact.Comment do
  use CaptainFact.Web, :model

  alias CaptainFact.{Source, User, Statement, Comment}

  schema "comments" do
    field :text, :string
    field :approve, :boolean

    field :score, :integer, virtual: true, default: 0

    belongs_to :source, Source
    belongs_to :user, User
    belongs_to :statement, Statement
    timestamps()
  end

  def full(query, source_required \\ false) do
    query
    |> join(:inner, [c], s in assoc(c, :statement))
    |> join(:inner, [c, _], u in assoc(c, :user))
    |> with_source(source_required)
    |> join(:left, [c, _, _, _], v in fragment("
        SELECT sum(value) AS score, comment_id
        FROM   votes
        GROUP BY comment_id
       "), v.comment_id == c.id)
    |> select([c, s, u, source, v], %{
        id: c.id,
        approve: c.approve,
        source: source,
        statement_id: c.statement_id,
        text: c.text,
        inserted_at: c.inserted_at,
        updated_at: c.updated_at,
        score: v.score,
        user: %{id: u.id, name: u.name, username: u.username}
      })
  end

  def with_source(query, required = true) do
    from c in query, join: source in Source, on: [id: c.source_id]
  end

  def with_source(query, required = false) do
    from c in query, left_join: source in Source, on: [id: c.source_id]
  end

  @required_fields ~w(statement_id)a
  @optional_fields ~w(approve text)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:source)
    |> put_source()
    |> validate_required(@required_fields)
    |> validate_source_or_text()
    |> validate_length(:text, min: 1, max: 240)
  end

  defp put_source(struct = %{changes: %{source: %{changes: %{url: url}}}}) do
    case CaptainFact.Repo.get_by(CaptainFact.Source, url: url) do
      nil -> struct
      source -> put_assoc(struct, :source, source)
    end
  end

  defp put_source(struct), do: struct

  defp validate_source_or_text(changeset) do
    source = get_field(changeset, :source)
    text = get_field(changeset, :text)
    has_source = (source && source.url && String.length(source.url)) || false
    has_text = (text && String.length(text)) || false
    case has_text || has_source do
      false ->
        changeset
        |> add_error(:text, "You must set at least a source or a text")
        |> add_error(:source, "You must set at least a source or a text")
      _ -> changeset
    end
  end
end
