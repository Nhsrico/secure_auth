defmodule SecureAuthWeb.FormatHelpers do
  # Show only last 4 chars of hashes/tokens
  def mask_token(nil), do: "—"
  def mask_token(tok) when is_binary(tok), do: "••••" <> String.slice(tok, -4..-1)

  # IP tuple/binary -> string
  def ip_to_string({_,_,_,_}=ip), do: ip |> :inet.ntoa() |> to_string()
  def ip_to_string({_,_,_,_,_,_,_,_}=ip6), do: ip6 |> :inet.ntoa() |> to_string()
  def ip_to_string(ip) when is_binary(ip), do: ip
  def ip_to_string(_), do: "—"

  # Pretty time
  def fmt_time(nil), do: "—"
  def fmt_time(%DateTime{}=dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  def fmt_time(%NaiveDateTime{}=dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  def fmt_time(_), do: "—"
end
