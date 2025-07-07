defmodule SecureAuth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    # New secure fields
    field :name, :string
    field :phone_number, :string
    field :ssn_encrypted, :binary
    field :passport_number_encrypted, :binary
    field :next_of_kin_passport_encrypted, :binary
    field :verification_status, :string, default: "pending"

    # Virtual fields for form input (before encryption)
    field :ssn, :string, virtual: true, redact: true
    field :passport_number, :string, virtual: true, redact: true
    field :next_of_kin_passport, :string, virtual: true, redact: true

    # 2FA fields
    field :totp_secret_encrypted, :binary
    field :two_factor_enabled, :boolean, default: false
    field :backup_codes_encrypted, :binary
    field :totp_last_used_at, :utc_datetime

    # Virtual fields for 2FA
    field :totp_secret, :string, virtual: true, redact: true
    field :backup_codes, {:array, :string}, virtual: true, redact: true
    field :totp_code, :string, virtual: true, redact: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_email` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, SecureAuth.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user registration changeset for new users with all required fields.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :name,
      :phone_number,
      :ssn,
      :passport_number,
      :next_of_kin_passport
    ])
    |> validate_required([:email, :password, :name, :phone_number, :next_of_kin_passport])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:phone_number, ~r/^\+?[1-9]\d{1,14}$/,
      message: "must be a valid phone number"
    )
    |> validate_ssn_or_passport()
    |> validate_password(opts)
    |> validate_email(opts)
    |> encrypt_sensitive_fields()
  end

  defp validate_ssn_or_passport(changeset) do
    ssn = get_change(changeset, :ssn)
    passport = get_change(changeset, :passport_number)

    cond do
      ssn && passport ->
        add_error(changeset, :base, "Please provide either SSN or passport number, not both")

      ssn ->
        changeset
        |> validate_format(:ssn, ~r/^\d{3}-?\d{2}-?\d{4}$/,
          message: "must be a valid SSN format (XXX-XX-XXXX)"
        )

      passport ->
        changeset
        |> validate_format(:passport_number, ~r/^[A-Z0-9]{6,15}$/,
          message: "must be a valid passport number"
        )

      true ->
        add_error(changeset, :base, "Either SSN or passport number is required")
    end
  end

  defp encrypt_sensitive_fields(changeset) do
    changeset
    |> encrypt_field(:ssn, :ssn_encrypted)
    |> encrypt_field(:passport_number, :passport_number_encrypted)
    |> encrypt_field(:next_of_kin_passport, :next_of_kin_passport_encrypted)
  end

  defp encrypt_field(changeset, virtual_field, encrypted_field) do
    value = get_change(changeset, virtual_field)

    if value do
      # For demo purposes, we'll use simple base64 encoding
      # In production, you'd use proper encryption with a secret key
      encrypted_value = Base.encode64(value)

      changeset
      |> put_change(encrypted_field, encrypted_value)
      |> delete_change(virtual_field)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%SecureAuth.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
