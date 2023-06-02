defmodule Beacon.LiveAdmin.HomePage do
  @moduledoc false

  use Beacon.LiveAdmin.PageBuilder

  @impl true
  def menu_link do
    {:ok, "Home"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Home</div>
    <pre><code><%= inspect(@live_action, pretty: true) %></code></pre>
    <pre><code><%= inspect(Phoenix.Router.routes(DemoWeb.Router), pretty: true) %></code></pre>
    """
  end
end
