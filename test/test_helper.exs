ExUnit.start()

defmodule TestHelper do
  def padded_date(d) do
    month =
      d.month
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    day =
      d.day
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{d.year}#{month}#{day}"
  end

  def with_fake_serial(pnr) do
    "#{pnr}-1111"
  end
end
