
defmodule Mix.Tasks.Admin.Create do
  use Mix.Task

  @shortdoc "Create or promote an admin user (idempotent)"
  @moduledoc """
  Create or promote an admin user. If the user exists, it will be promoted.

  ## Usage

      mix admin.create email=me@example.com password=SuperSecret123 \
        name="Site Admin" confirmed=true \
        phone=+10000000000 passport=P12345678 kin_passport=K87654321

  Options:
    * email          - required
    * password       - required for new user (ignored when promoting existing)
    * name           - optional for new user (default: "Admin")
    * confirmed      - "true" | "false" (default: "true")
    * phone          - phone number (required by your changeset)
    * ssn            - optional; if not provided, passport may be used instead
    * passport       - optional; required if ssn is not provided
    * kin_passport   - Next of kin passport (required by your changeset)
  """

  def run(args) do
    Mix.Task.run("app.start")

    opts =
      args
      |> Enum.map(&String.split(&1, "=", parts: 2))
      |> Enum.into(%{}, fn
        [k, v] -> {String.to_atom(k), v}
        [k] -> {String.to_atom(k), ""}
      end)

    email      = fetch!(opts, :email)
    password   = Map.get(opts, :password)
    name       = Map.get(opts, :name, "Admin")
    confirmed? = parse_bool(Map.get(opts, :confirmed, "true"))

    # Required-by-your-schema fields (defaults if not provided)
    phone      = Map.get(opts, :phone)        || "+10000000000"
    ssn        = empty_to_nil(Map.get(opts, :ssn))
    passport   = empty_to_nil(Map.get(opts, :passport))
    kin_pass   = Map.get(opts, :kin_passport) || "K#{rand_digits(8)}"

    # Enforce either ssn or passport
    if is_nil(ssn) and is_nil(passport) do
      # provide a default passport when neither is given
      passport = "P#{rand_digits(8)}"
      opts      = Map.put(opts, :passport, passport)
      :ok = :ok
    end

    alias SecureAuth.{Accounts, Repo}

    user =
      case Accounts.get_user_by_email(email) do
        nil ->
          password || Mix.raise("password= is required when creating a new user")

          # Build params expected by your registration changeset
          params = %{
            email: email,
            password: password,
            name: name,
            phone_number: phone,
            # your changeset encrypts these internally; pass plaintext here:
            ssn: ssn,
            passport_number: passport || "P#{rand_digits(8)}",
            next_of_kin_passport: kin_pass
          }

          case Accounts.register_user(params) do
            {:ok, u} -> u
            {:error, cs} ->
              IO.puts("Failed to create user:")
              IO.inspect(cs.errors, label: "errors")
              Mix.raise("user creation failed")
          end

        u ->
          u
      end

    ch =
      Ecto.Changeset.change(user,
        is_admin: true,
        confirmed_at: (confirmed? && DateTime.utc_now()) |> DateTime.truncate(:second)  || user.confirmed_at
      )

    case Repo.update(ch) do
      {:ok, u}   -> Mix.shell().info("Admin ready: #{u.email} (id=#{u.id})")
      {:error, cs} ->
        IO.puts("Failed to promote user:")
        IO.inspect(cs.errors, label: "errors")
        Mix.raise("admin promotion failed")
    end
  end

  ## helpers

  defp fetch!(m, k), do: Map.get(m, k) || Mix.raise("#{k}= is required")
  defp parse_bool("true"),  do: true
  defp parse_bool("false"), do: false
  defp parse_bool(true),    do: true
  defp parse_bool(false),   do: false
  defp parse_bool(_),       do: true

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(v),  do: v

  defp rand_digits(n) do
    1..n |> Enum.map(fn _ -> :rand.uniform(10) - 1 end) |> Enum.join()
  end
end
