alias SecureAuth.{Repo, Accounts}
user = Accounts.get_user_by_email("john@example.com")
if user && user.backup_codes_encrypted do
  codes = user.backup_codes_encrypted |> Base.decode64!() |> :erlang.binary_to_term()
  IO.puts("First backup code: #{List.first(codes)}")
else
  IO.puts("No backup codes found")
end
