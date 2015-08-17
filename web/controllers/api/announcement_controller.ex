defmodule Constable.Api.AnnouncementController do
  use Constable.Web, :controller

  alias Constable.Announcement
  alias Constable.Services.AnnouncementCreator

  plug :scrub_params, "announcement" when action in [:create, :update]

  def index(conn, _params) do
    announcements = Repo.all(Announcement)
    render(conn, "index.json", announcements: announcements)
  end

  def create(conn,
      %{"announcement" => announcement_params, "interest_names" => interest_names}) do
    current_user = current_user(conn)
    announcement_params = Map.put(announcement_params, "user_id", current_user.id)

    case AnnouncementCreator.create(announcement_params, interest_names) do
      {:ok, announcement} ->
        conn
        |> put_status(:created)
        |> render("show.json", announcement: announcement)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Constable.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    announcement = Repo.get!(Announcement, id)
    render conn, "show.json", announcement: announcement
  end

  def update(conn, %{"id" => id, "announcement" => announcement_params}) do
    current_user = current_user(conn)
    announcement = Repo.get!(Announcement, id)
    changeset = Announcement.changeset(announcement, :update, announcement_params)

    if announcement.user_id == current_user.id do
      case Repo.update(changeset) do
        {:ok, announcement} ->
          render(conn, "show.json", announcement: announcement)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(Constable.ChangesetView, "error.json", changeset: changeset)
      end
    else
      unauthorized(conn)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = current_user(conn)
    announcement = Repo.get!(Announcement, id)

    if announcement.user_id == current_user.id do
      Repo.delete!(announcement)
      send_resp(conn, 204, "")
    else
      unauthorized(conn)
    end
  end
end