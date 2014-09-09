defmodule Placid.Response.Helpers do
  @moduledoc """
  Placid bundles these response helpers with handlers to 
  assist in sending a response:

  * `render/4` - `conn`, `data`, `opts` - sends a normal response.
  * `halt!/2` - `conn`, `opts` - ends the response.
  * `not_found/1` - `conn`, `message` - sends a 404 (Not found) response.
  * `raw/1` - `conn` - sends response as-is. It is expected
    that status codes, headers, body, etc have been set by
    the handler action.

  #### Example

      defmodule Hello do
        use Placid.Handler

        def index(conn, []) do
          render conn, "showing index handler"
        end

        def show(conn, args) do
          render conn, "showing page \#{args[:id]}"
        end

        def create(conn, []) do
          render conn, "page created"
        end
      end
  """

  import Plug.Conn
  alias Placid.Response.StatusCodes

  @doc """
  sets connection status

  ## Arguments

  * `conn` - `Plug.Conn`
  * `status_code` - `Integer`

  ## Returns

  `Plug.Conn`
  """
  def status(conn, status_code) when is_integer(status_code)
                                when is_atom(status_code) do
    status = status_code |> StatusCodes.find
    %Plug.Conn{ conn | status: status.code, 
                       state: :set }
  end

  @doc """
  sets response headers

  ## Arguments

  * `conn` - `Plug.Conn`
  * `status_code` - `Integer`

  ## Returns

  `Plug.Conn`
  """
  def headers(conn, headers) do
    %Plug.Conn{ conn | resp_headers: headers, 
                       state: :set }
  end

  @doc """
  Sends response as-is. It is expected that status codes,
  headers, body, etc have been set by the handler
  action.

  ## Arguments

  * `conn` - `Plug.Conn`

  ## Returns

  `Plug.Conn`
  """
  def raw(conn) do
    conn |> send_resp
  end

  @doc """
  Sends a normal response.

  ## Arguments

  * `conn` - `Plug.Conn`
  * `data` - `Keyword`
  * `opts` - `Keyword`

  ## Returns

  `Plug.Conn`
  """
  def render(conn, data, opts \\ []) do
    opts = [ status: 200 ] |> Keyword.merge opts
    status = StatusCodes.find opts[:status]
    conn
      |> put_resp_content_type_if_not_sent(opts[:content_type] || "text/html")
      |> send_resp_if_not_sent(status.code, data)
  end

  @doc """
  Ends the response.

  ## Arguments

  * `conn` - `Plug.Conn`
  * `opts` - `Keyword`

  ## Returns

  `Plug.Conn`
  """
  def halt!(conn, opts \\ []) do
    opts = [ status: 401] |> Keyword.merge opts
    status = StatusCodes.find opts[:status]
    conn
      |> send_resp_if_not_sent(status.code, status.reason)
  end

  @doc """
  Sends a 404 (Not found) response.

  ## Arguments

  * `conn` - `Plug.Conn`

  ## Returns

  `Plug.Conn`
  """
  def not_found(conn, message \\ "Not Found") do
    conn
      |> send_resp_if_not_sent(404, message)
  end

  @doc """
  Forwards the response to another handler action.

  ## Arguments

  * `conn` - `Plug.Conn`
  * `handler` - `Atom`
  * `action` - `Atom`
  * `args` - `Keyword`

  ## Returns

  `Plug.Conn`
  """
  def forward(conn, handler, action, args \\ []) do
    handler.call conn, [ action: action, args: args ++ conn.params ]
  end

  @doc """
  Redirects the response.

  ## Arguments

  * `conn` - `Plug.Conn`
  * `location` - `String`
  * `opts` - `Keyword`

  ## Returns

  `Plug.Conn`
  """
  def redirect(conn, location, opts \\ []) do
    opts = [ status: 302 ] |> Keyword.merge opts
    status = StatusCodes.find opts[:status]    
    conn
      |> put_resp_header_if_not_sent("Location", location)
      |> send_resp_if_not_sent(status.code, status.reason)
  end

  defp put_resp_header_if_not_sent(%Plug.Conn{ state: :sent } = conn, _, _) do
    conn
  end
  defp put_resp_header_if_not_sent(conn, key, value) do
    conn |> put_resp_header(key, value)
  end

  defp put_resp_content_type_if_not_sent(%Plug.Conn{ state: :sent } = conn, _) do
    conn
  end
  defp put_resp_content_type_if_not_sent(conn, resp_content_type) do
    conn |> put_resp_content_type(resp_content_type)
  end

  defp send_resp_if_not_sent(%Plug.Conn{ state: :sent } = conn, _, _) do
    conn
  end
  defp send_resp_if_not_sent(conn, status, body) do
    conn |> send_resp(status, body)
  end
end
