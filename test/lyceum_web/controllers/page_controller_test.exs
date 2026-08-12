defmodule LyceumWeb.PageControllerTest do
  use LyceumWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Open source learning management system"
  end
end
