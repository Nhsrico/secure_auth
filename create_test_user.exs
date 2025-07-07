alias SecureAuth.{Repo, Accounts}

user_params = %{
  "email" => "test@example.com",
  "password" => "testpass123456",
  "name" => "Test User",
  "phone_number" => "+1234567890",
  "next_of_kin_passport" => "TEST123456",
  "ssn" => "123-45-6789"
}

case Accounts.register_user(user_params) do
  {:ok, user} ->
    confirmed_user =
      user
      |> SecureAuth.Accounts.User.confirm_changeset()
      |> Repo.update!()

    IO.puts("✅ Created test user: #{confirmed_user.email}")
    IO.puts("✅ 2FA enabled: #{confirmed_user.two_factor_enabled}")

  {:error, changeset} ->
    IO.puts("❌ Failed: #{inspect(changeset.errors)}")
end
