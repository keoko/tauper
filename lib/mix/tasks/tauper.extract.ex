defmodule Mix.Tasks.Tauper.Extract do
  @moduledoc """
  Extract data from Tauper application and save to JSON file.

  This task can be used locally or provides commands for remote extraction.

  ## Usage

  Local extraction for LIVE data (requires app to be running with a name):

      # In one terminal - start server with a node name:
      iex --sname tauper -S mix phx.server

      # In another terminal - extract from running app:
      mix tauper.extract game_codes --node tauper
      mix tauper.extract game_codes --node tauper --output codes.json

  Local extraction for STATIC data (doesn't need running app):

      mix tauper.extract periodic_table --output table.json

  Remote extraction (fly.io):

      mix tauper.extract game_codes --remote

  ## Available data sources

    * game_codes - List all active game codes
    * all_games - Full state of all active games
    * periodic_table - Full periodic table data
    * custom - Run custom Elixir code (use --eval flag)

  ## Options

    * --output, -o - Output filename (default: output.json)
    * --node, -n - Node name to connect to for live data (e.g., tauper)
    * --remote, -r - Show command for remote fly.io execution
    * --eval, -e - Custom Elixir expression to evaluate
    * --pretty, -p - Pretty print JSON (default: true)

  ## Examples

      # Extract game codes from running app
      mix tauper.extract game_codes --node tauper

      # Extract all game states from remote
      mix tauper.extract all_games --remote

      # Extract periodic table (static data, no running app needed)
      mix tauper.extract periodic_table -o elements.json

      # Custom extraction from running app
      mix tauper.extract custom -e "Enum.map(1..5, & &1)" --node tauper

      # Get remote command for fly.io
      mix tauper.extract game_codes --remote
  """

  @shortdoc "Extract data from Tauper to JSON"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, args, _} =
      OptionParser.parse(args,
        aliases: [o: :output, r: :remote, e: :eval, p: :pretty, n: :node],
        strict: [output: :string, remote: :boolean, eval: :string, pretty: :boolean, node: :string]
      )

    data_source = List.first(args) || "game_codes"
    output_file = opts[:output] || "output.json"
    pretty = Keyword.get(opts, :pretty, true)

    # Build the Elixir expression to run
    expression = build_expression(data_source, opts[:eval])

    cond do
      opts[:remote] ->
        show_remote_command(expression, output_file)

      opts[:node] ->
        extract_from_node(expression, output_file, pretty, opts[:node])

      requires_live_data?(data_source) ->
        Mix.raise("""
        This data source requires a running application.

        Start your server with a name in one terminal:
          iex --sname tauper -S mix phx.server

        Then run this command with --node flag:
          mix tauper.extract #{data_source} --node tauper
        """)

      true ->
        extract_standalone(expression, output_file, pretty)
    end
  end

  defp build_expression("game_codes", _), do: "Tauper.Games.list_game_codes()"
  defp build_expression("all_games", _), do: "Tauper.Games.list_game_codes() |> Enum.map(&Tauper.Games.game/1)"
  defp build_expression("periodic_table", _), do: "Tauper.Games.Tables.EducemFar.table()"
  defp build_expression("custom", eval) when is_binary(eval), do: eval
  defp build_expression("custom", nil) do
    Mix.raise("Custom data source requires --eval flag. Example: mix tauper.extract custom -e 'YourModule.function()'")
  end
  defp build_expression(unknown, _) do
    Mix.raise("Unknown data source: #{unknown}. Available: game_codes, periodic_table, custom")
  end

  # Check if data source requires live application (GenServer, Registry, ETS, etc.)
  defp requires_live_data?("game_codes"), do: true
  defp requires_live_data?("all_games"), do: true
  defp requires_live_data?("periodic_table"), do: false
  defp requires_live_data?("custom"), do: false  # Assume custom can be static, user can use --node if needed

  # Extract from a running node using distributed Erlang (like RPC)
  defp extract_from_node(expression, output_file, pretty, node_name) do
    target_node = :"#{node_name}@#{hostname()}"

    Mix.shell().info("Connecting to node: #{target_node}")
    Mix.shell().info("Extracting: #{expression}")
    Mix.shell().info("Output: #{output_file}")

    # Start distributed Erlang on this node with shortnames
    case Node.start(:"extract_#{:os.system_time(:millisecond)}", :shortnames) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, reason} -> Mix.raise("Failed to start node: #{inspect(reason)}")
    end

    # Read the Erlang cookie from ~/.erlang.cookie
    cookie = read_erlang_cookie()
    Node.set_cookie(Node.self(), cookie)

    # Try to connect
    case Node.connect(target_node) do
      true ->
        Mix.shell().info("✓ Connected to #{target_node}")

        # Execute remotely
        result = :rpc.call(target_node, Code, :eval_string, [expression])

        case result do
          {data, _bindings} ->
            write_json(data, output_file, pretty)

          {:badrpc, reason} ->
            Mix.raise("RPC failed: #{inspect(reason)}")
        end

      false ->
        Mix.raise("""
        Failed to connect to node: #{target_node}

        Make sure your server is running with:
          iex --sname #{node_name} -S mix phx.server

        Check that the node name matches and is on the same machine.
        """)

      :ignored ->
        Mix.raise("Connection ignored by remote node")
    end
  end

  # Extract from standalone app (static data only)
  defp extract_standalone(expression, output_file, pretty) do
    Mix.shell().info("Extracting (standalone): #{expression}")
    Mix.shell().info("Output: #{output_file}")

    # Ensure the application is started
    Mix.Task.run("app.start")

    # Evaluate the expression
    {result, _} = Code.eval_string(expression)

    write_json(result, output_file, pretty)
  end

  defp write_json(data, output_file, pretty) do
    # Encode to JSON
    json_opts = if pretty, do: [pretty: true], else: []
    json = Jason.encode!(data, json_opts)

    # Write to file
    File.write!(output_file, json)

    Mix.shell().info("✓ Data extracted successfully!")
    Mix.shell().info("\nPreview:")

    # Show preview (first 500 chars)
    preview = String.slice(json, 0, 500)
    Mix.shell().info(preview)

    if String.length(json) > 500 do
      Mix.shell().info("...")
    end
  end

  defp hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  defp read_erlang_cookie do
    cookie_file = Path.join(System.user_home!(), ".erlang.cookie")

    if File.exists?(cookie_file) do
      cookie_file
      |> File.read!()
      |> String.trim()
      |> String.to_atom()
    else
      # Fallback to the current node's cookie (which might be randomly generated)
      Node.get_cookie()
    end
  end

  defp show_remote_command(expression, output_file) do
    # Escape any double quotes in the expression for nested quoting
    escaped_expr = String.replace(expression, "\"", "\\\"")
    elixir_cmd = "IO.puts(Jason.encode!(#{escaped_expr}, pretty: true))"

    # Use single quotes on outside to avoid bash history expansion issues with !
    fly_cmd = "fly ssh console -C '/app/bin/tauper rpc \"#{elixir_cmd}\"' > #{output_file}"

    Mix.shell().info("Remote extraction command for fly.io:\n")
    Mix.shell().info(fly_cmd)
    Mix.shell().info("\nOr run interactively:")
    Mix.shell().info("  fly ssh console")
    Mix.shell().info("  /app/bin/tauper rpc '#{elixir_cmd}' > #{output_file}")
  end
end
