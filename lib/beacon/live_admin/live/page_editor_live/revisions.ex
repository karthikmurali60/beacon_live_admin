defmodule Beacon.LiveAdmin.PageEditorLive.Revisions do
  @moduledoc false

  use Beacon.LiveAdmin.PageBuilder
  alias Beacon.LiveAdmin.Content

  @impl true
  def menu_link("/pages", :revisions), do: {:submenu, "Pages"}
  def menu_link(_, _), do: :skip

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    socket =
      assign(socket,
        page_id: id,
        events: Content.list_page_events(socket.assigns.beacon_page.site, id),
        show_variant_modal: false,
        variant_template: nil
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_modal", params, socket) do
    %{"variant_id" => variant_id, "event_id" => event_id} = params
    event = Enum.find(socket.assigns.events, &(&1.id == event_id))
    variant = Enum.find(event.snapshot.page.variants, &(&1.id == variant_id))

    {:noreply, assign(socket, show_variant_modal: true, variant_template: variant.template)}
  end

  def handle_event("hide_modal", _, socket) do
    {:noreply, assign(socket, show_variant_modal: false, variant_template: nil)}
  end

  def handle_event("variant_template_editor_lost_focus", _, socket) do
    {:noreply, socket}
  end

  def handle_event(<<"template-", _::binary>>, _, socket) do
    {:noreply, socket}
  end

  def handle_event(<<"schema-", _::binary>>, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Beacon.LiveAdmin.AdminComponents.page_menu socket={@socket} site={@beacon_page.site} current_action={@live_action} page_id={@page_id} />

      <ol class="relative border-l border-gray-200">
        <%= for event <- @events do %>
          <.revision event={event} />
        <% end %>
      </ol>

      <.modal :if={@show_variant_modal} id="variant-modal" on_cancel={JS.push("hide_modal")} show>
        <div class="w-full mt-2">
          <div class="py-3 bg-[#282c34] rounded-lg">
            <LiveMonacoEditor.code_editor
              path="variant_template"
              style="min-height: 200px; width: 100%;"
              value={@variant_template}
              opts={Map.merge(LiveMonacoEditor.default_opts(), %{"language" => "json", "readOnly" => "true"})}
            />
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  ## FUNCTION COMPONENTS

  attr :event, :map
  attr :latest, :boolean, default: false

  def revision(assigns) do
    ~H"""
    <li class="group mb-10 ml-6">
      <span class="absolute flex items-center justify-center w-6 h-6 bg-blue-100 rounded-full -left-3 ring-8 ring-white">
        <.icon :if={@event.event == :published} name="hero-eye-solid" class="h-4 w-4 text-blue-800" />
        <.icon :if={@event.event == :created} name="hero-document-plus-solid" class="h-4 w-4 text-blue-800" />
      </span>
      <h3 class="flex items-center mb-1 text-lg font-semibold text-gray-900">
        <%= Phoenix.Naming.humanize(@event.event) %> <span class="text-sm text-gray-500 ml-2"><%= format_datetime(@event.inserted_at) %></span>
        <span class="hidden group-first:block bg-blue-100 text-blue-800 text-sm font-medium mr-2 px-2.5 py-0.5 rounded ml-3">Latest</span>
      </h3>

      <ol :if={@event.snapshot} class="space-y-3">
        <li>
          <h4 class="text-gray-600 text-bold">Path</h4>
          <%= @event.snapshot.page.path %>
        </li>
        <li>
          <h4 class="text-gray-600">Title</h4>
          <%= @event.snapshot.page.title %>
        </li>
        <li>
          <h4 class="text-gray-600">Description</h4>
          <%= @event.snapshot.page.description %>
        </li>
        <li>
          <h4 class="text-gray-600">Format</h4>
          <%= @event.snapshot.page.format %>
        </li>
        <li>
          <h4 class="text-gray-600">Template</h4>
          <div class="w-full mt-2">
            <div class="py-3 bg-[#282c34] rounded-lg">
              <LiveMonacoEditor.code_editor
                path={"template-" <> @event.snapshot.id}
                style="min-height: 200px; width: 100%;"
                value={@event.snapshot.page.template}
                opts={Map.merge(LiveMonacoEditor.default_opts(), %{"language" => "html", "readOnly" => "true"})}
              />
            </div>
          </div>
        </li>
        <li>
          <h4 class="text-gray-600">Schema</h4>
          <div class="w-full mt-2">
            <div class="py-3 bg-[#282c34] rounded-lg">
              <LiveMonacoEditor.code_editor
                path={"schema-" <> @event.snapshot.id}
                style="min-height: 200px; width: 100%;"
                value={Jason.encode!(@event.snapshot.page.raw_schema, pretty: true)}
                opts={Map.merge(LiveMonacoEditor.default_opts(), %{"language" => "json", "readOnly" => "true"})}
              />
            </div>
          </div>
        </li>
        <li>
          <h4 class="text-gray-600">Meta Tags</h4>
          <%= render_meta_tags(@event.snapshot.page.meta_tags) %>
        </li>
        <li>
          <h4 class="text-gray-600">Variants</h4>
          <.table id="variants" rows={variants(@event.snapshot.page)}>
            <:col :let={variant} label="name">
              <%= variant.name %>
            </:col>
            <:col :let={variant} label="weight">
              <%= variant.weight %>
            </:col>
            <:col :let={variant} label="template">
              <.link class="hover:underline text-blue-600" phx-click={JS.push("show_modal", value: %{event_id: @event.id, variant_id: variant.id})}>
                Click here
              </.link>
            </:col>
          </.table>
        </li>
      </ol>
    </li>
    """
  end

  ## UTILS

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp render_meta_tags(meta_tags) do
    attributes =
      meta_tags
      |> Enum.flat_map(fn meta_tag -> Map.keys(meta_tag) end)
      |> Enum.uniq()
      |> Enum.sort(fn a, b ->
        case {a, b} do
          {"name", _} -> true
          {_, "name"} -> false
          {"property", _} -> true
          {_, "property"} -> false
          {"content", _} -> true
          {_, "content"} -> false
          {a, b} -> a <= b
        end
      end)

    assigns = %{attributes: attributes, meta_tags: meta_tags}

    ~H"""
    <.table id="meta_tags" rows={@meta_tags}>
      <:col :let={meta_tag} :for={attr <- @attributes} label={attr}>
        <%= meta_tag[attr] %>
      </:col>
    </.table>
    """
  end

  defp variants(%{variants: variants}) when is_list(variants), do: variants
  defp variants(_page), do: []
end
