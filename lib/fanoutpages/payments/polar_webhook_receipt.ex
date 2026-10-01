defmodule Fanoutpages.Payments.PolarWebhookReceipt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "polar_webhook_receipts" do
    field :webhook_id, :string
    field :event_type, :string
    field :payload_sha256, :string
    field :resource_type, :string
    field :resource_id, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [:webhook_id, :event_type, :payload_sha256, :resource_type, :resource_id])
    |> validate_required([:webhook_id, :event_type])
    |> unique_constraint(:webhook_id)
  end
end
