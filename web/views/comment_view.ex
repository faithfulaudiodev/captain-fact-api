defmodule CaptainFact.CommentView do
  use CaptainFact.Web, :view

  alias CaptainFact.{ CommentView, UserView }

  def render("show.json", %{comment: comment}) do
    render_one(comment, CommentView, "comment.json")
  end

  def render("index.json", %{comments: comments}) do
    render_many(comments, CommentView, "comment.json")
  end

  def render("comment.json", %{comment: comment}) do
    user = if Ecto.assoc_loaded?(comment.user) do
      UserView.render("show_public.json", %{user: comment.user})
    else
      nil
    end
    %{
      id: comment.id,
      user: UserView.render("show_public.json", %{user: comment.user}),
      statement_id: comment.statement_id,
      text: comment.text,
      approve: comment.approve,
      inserted_at: comment.inserted_at,
      score: comment.score,
      source: render_source(comment.source)
    }
  end

  defp render_source(nil), do: nil

  defp render_source(source) do
    %{
      url: source.url,
      title: source.title,
      language: source.language,
      site_name: source.site_name
    }
  end
end
