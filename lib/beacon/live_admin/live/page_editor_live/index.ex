defmodule Beacon.LiveAdmin.PageEditorLive.Index do
  @moduledoc false

  use Beacon.LiveAdmin.PageBuilder
  alias Beacon.LiveAdmin.Content

  on_mount {Beacon.LiveAdmin.Hooks.Authorized, {:page_editor, :index}}

  @impl true
  def menu_link(_, :index), do: {:root, "Pages"}

  @impl true
  def mount(_params, _session, socket) do
    pages = list_pages(socket.assigns.beacon_page.site)
    {:ok, assign(socket, :pages, pages)}
  end

  @impl true
  def handle_params(%{"query" => query}, _uri, socket) do
    pages = list_pages(socket.assigns.beacon_page.site, query: query)
    {:noreply, assign(socket, :pages, pages)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    path =
      beacon_live_admin_path(
        socket,
        socket.assigns.beacon_page.site,
        "/pages?query=#{query}"
      )

    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Pages
      <:actions>
        <.link patch={beacon_live_admin_path(@socket, @beacon_page.site, "/pages/new")} phx-click={JS.push_focus()}>
          <.button class="uppercase">Create New Page</.button>
        </.link>
      </:actions>
    </.header>

    <div class="my-4">
      <.simple_form :let={f} for={%{}} as={:search} phx-change="search">
        <div class="flex gap-4 items-center">
          <div class="flex-grow">
            <.input field={f[:query]} type="search" autofocus={true} placeholder="Search by path or title (showing up to 20 results)" />
          </div>
        </div>
      </.simple_form>
    </div>

    <.table id="pages" rows={@pages} row_click={fn page -> JS.navigate(beacon_live_admin_path(@socket, @beacon_page.site, "/pages/#{page.id}")) end}>
      <:col :let={page} label="Title"><%= page.title %></:col>
      <:col :let={page} label="Path"><%= page.path %></:col>
      <:col :let={page} label="Status"><%= display_status(page.status) %></:col>
      <:action :let={page}>
        <div class="sr-only">
          <.link navigate={beacon_live_admin_path(@socket, @beacon_page.site, "/pages/#{page.id}")}>Show</.link>
        </div>
        <.link patch={beacon_live_admin_path(@socket, @beacon_page.site, "/pages/#{page.id}")}>
          <.icon name="hero-pencil-square" />
        </.link>
      </:action>
    </.table>
    """
  end

  defp list_pages(site, opts \\ []) do
    site
    |> Content.list_pages(opts)
    |> Enum.map(fn page ->
      Map.put(page, :status, Content.get_latest_page_event(page.site, page.id).event)
    end)
  end

  defp display_status(:unpublished), do: "Unpublished"
  defp display_status(:published), do: "Published"
  defp display_status(:created), do: "Draft"
end
