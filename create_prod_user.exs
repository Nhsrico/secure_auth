alias SecureAuth.{Repo, Accounts}

admin_params = %{
  "email" => "admin@secure-auth-prod.fly.dev",
  "password" => "SecurePass2024",
  "name" => "Production Admin",
  "phone_number" => "+1555000001",
  "next_of_kin_passport" => "ADMIN2024",
  "ssn" => "999-88-7777"
}

case Accounts.register_user(admin_params) do
  {:ok, user} ->
    confirmed_user =
      user
      |> SecureAuth.Accounts.User.confirm_changeset()
      |> Repo.update!()

    IO.puts("✅ Created admin user: #{confirmed_user.email}")
    IO.puts("✅ Password: SecurePass2024")
    IO.puts("✅ Account confirmed: #{not is_nil(confirmed_user.confirmed_at)}")

  {:error, changeset} ->
    IO.puts("❌ Failed: #{inspect(changeset.errors)}")
end
