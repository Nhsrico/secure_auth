alias SecureAuth.{Repo, Accounts}

user = Accounts.get_user_by_email("john@example.com")

if user do
  case Accounts.update_user_password(user, %{"password" => "testpass123456"}) do
    {:ok, updated_user, _tokens} ->
      confirmed_user =
        updated_user |> SecureAuth.Accounts.User.confirm_changeset() |> Repo.update!()

      IO.puts("✅ User updated: #{confirmed_user.email}")
      IO.puts("✅ Account confirmed: #{not is_nil(confirmed_user.confirmed_at)}")
      IO.puts("✅ 2FA enabled: #{confirmed_user.two_factor_enabled}")
      IO.puts("✅ Test password: testpass123456")

    {:error, changeset} ->
      IO.puts("❌ Password update failed: #{inspect(changeset.errors)}")
  end
else
  IO.puts("❌ User not found")
end
