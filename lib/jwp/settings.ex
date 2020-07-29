defmodule Jwp.Settings do
  defmacro __using__(_) do
    quote do
      @app_id_length 10
      @app_id_pad ?0
      @app_id_sep ?:
    end
  end
end
