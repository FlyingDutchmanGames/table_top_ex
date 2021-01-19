defmodule TableTopEx.NifBridge do
    use Rustler, otp_app: :table_top_ex

    def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
