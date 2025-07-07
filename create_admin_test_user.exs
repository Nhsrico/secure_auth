alias SecureAuth.{Repo, Accounts}

admin_params = %{
  "email" => "admin@test.com",
  "password" => "adminpass123456",
  "name" => "Admin User",
  "phone_number" => "+1555000123",
  "next_of_kin_passport" => "ADMIN123",
  "ssn" => "999-11-2222"
}

case Accounts.register_user(admin_params) do
  {:ok, user} ->
    confirmed_user =
      user
      |> SecureAuth.Accounts.User.confirm_changeset()
      |> Repo.update!()

    IO.puts("✅ Created admin user: #{confirmed_user.email}")
    IO.puts("✅ Password: adminpass123456")
    IO.puts("✅ Account confirmed: #{not is_nil(confirmed_user.confirmed_at)}")

  {:error, changeset} ->
    IO.puts("❌ Failed: #{inspect(changeset.errors)}")
end
