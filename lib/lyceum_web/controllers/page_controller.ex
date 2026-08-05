defmodule LyceumWeb.PageController do
  use LyceumWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
