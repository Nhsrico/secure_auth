alias SecureAuth.{Repo, Accounts}

admin_params = %{
  "email" => "admin@secureauth.com",
  "password" => "adminpass123456",
  "name" => "Security Admin",
  "phone_number" => "+1555000000",
  "next_of_kin_passport" => "ADMIN123456",
  "ssn" => "999-99-9999"
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
    IO.puts("✅ Verification status: #{confirmed_user.verification_status}")

  {:error, changeset} ->
    IO.puts("❌ Failed to create admin: #{inspect(changeset.errors)}")
end
