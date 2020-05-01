defmodule Personnummer do
  @moduledoc """
  Validate Swedish personal identity numbers `Personnummer`.
  """

  defstruct [:date, :serial, :control, :separator, :coordination]

  def new(pnr_string) do
    matches =
      Regex.run(~r/^(\d{2}){0,1}(\d{2})(\d{2})(\d{2})([-|+]{0,1})(\d{3})(\d{0,1})$/, pnr_string)

    if is_nil(matches) or matches |> length < 7 do
      {:error, nil}
    else
      matches
      |> from_matches
    end
  end

  @doc """
  Formats a personal identity number in short format.

  ## Examples

      iex> {_, p} = Personnummer.new("199001011234")
      iex> Personnummer.format(p)
      "900101-1234"
      iex> {_, p} = Personnummer.new("199001010001")
      iex> Personnummer.format(p)
      "900101-0001"
      iex> {_, p} = Personnummer.new("199001610001")
      iex> Personnummer.format(p)
      "900161-0001"

  """
  def format(pnr) do
    Personnummer.format(pnr, true)
    |> String.slice(2..-1)
  end

  @doc """
  Formats a personal identity number in long format.

  ## Examples

      iex> {_, p} = Personnummer.new("9001011234")
      iex> Personnummer.format(p, true)
      "19900101-1234"

  """
  def format(pnr, true) do
    day =
      if pnr.coordination do
        pnr.date.day + 60
      else
        pnr.date.day
      end

    month =
      pnr.date.month
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    day =
      day
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    serial =
      pnr.serial
      |> Integer.to_string()
      |> String.pad_leading(3, "0")

    "#{pnr.date.year}#{month}#{day}-#{serial}#{pnr.control}"
  end

  @doc """
  Checks if the personal identity number is valid. Requres a valid date and a
  valid last four digits.

  ## Examples

      iex> {_, p} = %Personnummer{}
      iex> Personnummer.valid?(p)
      false

  """
  def valid?(_ = %Personnummer{date: nil}) do
    false
  end

  @doc """
  Checks if the personal identity number is valid. Requres a valid date and a
  valid last four digits.

  ## Examples

      iex> {_, p1} = Personnummer.new("19900101-0017")
      iex> {_, p2} = Personnummer.new("19900101-0018")
      iex> Personnummer.valid?(p1)
      true
      iex> Personnummer.valid?(p2)
      false

  """
  def valid?(pnr = %Personnummer{}) do
    short_date =
      Personnummer.format(pnr)
      |> String.slice(0..5)

    serial =
      pnr.serial
      |> Integer.to_string()
      |> String.pad_leading(3, "0")

    luhn_checksum("#{short_date}#{serial}") == pnr.control
  end

  @doc """
  Quick validation function to just validate a personal identity number from a
  string without preserving the struct with the personal identity number data.

  ## Examples
    iex> Personnummer.valid?("19900101-0017")
    true
    iex> Personnummer.valid?("19900101-0019")
    false
    iex> Personnummer.valid?("bogus")
    false
    iex> Personnummer.valid?("903030-0017")
    false

  """
  def valid?(pnr_str) when is_binary(pnr_str) do
    case Personnummer.new(pnr_str) do
      {:error, nil} -> false
      {:ok, pnr} -> Personnummer.valid?(pnr)
    end
  end

  @doc ~S"""
  Get the age of the person holding the personal identity number.

  ## Examples

      iex> now = DateTime.utc_now()
      iex> {_, x} = Date.new(now.year - 20, now.month, now.day)
      iex> pnr = "#{x.year}0101-1234"
      iex> {_, p} = Personnummer.new(pnr)
      iex> Personnummer.get_age(p)
      20

  """
  def get_age(pnr) do
    now = DateTime.utc_now()
    years_since_born = now.year - pnr.date.year

    cond do
      pnr.date.month > now.month -> years_since_born - 1
      pnr.date.month == now.month && pnr.date.day > now.day -> years_since_born - 1
      true -> years_since_born
    end
  end

  @doc """
  Returns true if the person behind the personal identity number is a female.

  ## Examples

      iex> {_, p} = Personnummer.new("19090903-6600")
      iex> Personnummer.is_female?(p)
      true

  """
  def is_female?(pnr) do
    pnr.serial
    |> rem(10)
    |> rem(2) == 0
  end

  @doc """
  Returns true if the person behind the personal identity number is a male.

  ## Examples

      iex> {_, p} = Personnummer.new("19900101-0017")
      iex> Personnummer.is_male?(p)
      true

  """
  def is_male?(pnr) do
    !Personnummer.is_female?(pnr)
  end

  @doc """
  Returns true if the parsed personal identity number is a coordination number.

  ## Examples

      iex> {_, p} = Personnummer.new("800161-3294")
      iex> Personnummer.is_coordination_number(p)
      true

  """
  def is_coordination_number(pnr) do
    pnr.coordination
  end

  defp matches_to_map(matches) do
    century =
      if Enum.at(matches, 1) == "" do
        1900
      else
        integer_at(matches, 1) * 100
      end

    %{
      century: century,
      year: integer_at(matches, 2),
      month: integer_at(matches, 3),
      day: integer_at(matches, 4),
      serial: integer_at(matches, 6),
      control: integer_at(matches, 7),
      separator: Enum.at(matches, 5)
    }
  end

  defp from_matches(matches) do
    matched_map = matches_to_map(matches)

    {day, is_coordination} =
      if matched_map.day > 60 do
        {matched_map.day - 60, true}
      else
        {matched_map.day, false}
      end

    {date_result, date} = Date.new(matched_map.century + matched_map.year, matched_map.month, day)

    if date_result == :error do
      {:error, nil}
    else
      {:ok,
       %Personnummer{
         date: date,
         serial: matched_map.serial,
         control: matched_map.control,
         separator: matched_map.separator,
         coordination: is_coordination
       }}
    end
  end

  defp integer_at(matches, pos) do
    Enum.at(matches, pos)
    |> Integer.parse()
    |> elem(0)
  end

  defp luhn_checksum(digits) do
    (10 -
       (digits
        |> String.split("", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> Enum.with_index()
        |> List.foldl(0, fn {digit, i}, acc -> acc + digit_to_add(i, digit) end)
        |> rem(10)))
    |> checksum
  end

  defp checksum(c) do
    case c do
      10 -> 0
      _ -> c
    end
  end

  defp digit_to_add(i, digit) do
    if rem(i, 2) == 0 do
      (digit * 2)
      |> double_digit
    else
      digit
    end
  end

  defp double_digit(digit) do
    if digit > 9 do
      digit - 9
    else
      digit
    end
  end
end
