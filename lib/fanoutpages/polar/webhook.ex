defmodule Fanoutpages.Polar.Webhook do
  @moduledoc false

  @tolerance_seconds 300

  def verify(raw_body, webhook_id, timestamp, signature)
      when is_binary(raw_body) and is_binary(webhook_id) and is_binary(timestamp) and
             is_binary(signature) do
    with {timestamp_integer, ""} <- Integer.parse(timestamp),
         true <- abs(System.system_time(:second) - timestamp_integer) <= @tolerance_seconds,
         true <- signature_matches_any_secret?(raw_body, webhook_id, timestamp, signature) do
      :ok
    else
      _ -> {:error, :invalid_signature}
    end
  end

  def verify(_raw_body, _webhook_id, _timestamp, _signature),
    do: {:error, :missing_signature_headers}

  defp signature_matches_any_secret?(raw_body, webhook_id, timestamp, signature) do
    message = "#{webhook_id}.#{timestamp}.#{raw_body}"

    Enum.any?(secret_candidates(), fn secret ->
      expected = :crypto.mac(:hmac, :sha256, secret, message)
      signature_matches?(signature, expected)
    end)
  end

  defp secret_candidates do
    secret = Application.fetch_env!(:fanoutpages, :polar_webhook_secret_key)
    encoded = String.replace_prefix(secret, "whsec_", "")

    case Base.decode64(encoded) do
      {:ok, decoded} -> Enum.uniq([secret, decoded])
      :error -> [secret]
    end
  end

  defp signature_matches?(header, expected) do
    header
    |> String.split(" ", trim: true)
    |> Enum.any?(fn candidate ->
      with "v1," <> encoded <- candidate,
           {:ok, signature} <- Base.decode64(encoded),
           true <- byte_size(signature) == byte_size(expected) do
        Plug.Crypto.secure_compare(signature, expected)
      else
        _ -> false
      end
    end)
  end
end
