defmodule PersonnummerTest do
  use ExUnit.Case
  doctest Personnummer

  test "test_invalid_date" do
    ["19901301-1111", "2017-02-29", "", "not-a-date"]
    |> Enum.each(fn tc ->
      {result, p} = Personnummer.new(tc)

      assert result == :error
      assert is_nil(p)
    end)
  end

  test "test_invalid luhn" do
    ["19900101-1111", "20160229-1111", "6403273814"]
    |> Enum.each(fn tc ->
      {result, p} = Personnummer.new(tc)

      assert result == :ok
      assert !is_nil(p)
      assert !Personnummer.valid?(p)
    end)
  end

  test "test valid social security number" do
    [
      "19900101-0017",
      "196408233234",
      "000101-0107",
      "510818-9167",
      "19130401+2931"
    ]
    |> Enum.each(fn tc ->
      {result, p} = Personnummer.new(tc)

      assert result == :ok
      assert !is_nil(p)
      assert Personnummer.valid?(p)
    end)
  end

  test "test age" do
    now = DateTime.utc_now()
    {_, x1} = Date.new(now.year - 20, now.month, now.day + 1)
    {_, x2} = Date.new(now.year - 20, now.month, now.day - 1)
    {_, x3} = Date.new(now.year - 100, 1, 1)

    twenty_tomorrow =
      x1
      |> TestHelper.padded_date
      |> TestHelper.with_fake_serial

    twenty_yesterday =
      x2
      |> TestHelper.padded_date
      |> TestHelper.with_fake_serial

    one_hundred =
      x3
      |> TestHelper.padded_date
      |> TestHelper.with_fake_serial

    %{
      "#{twenty_tomorrow}": 19,
      "#{twenty_yesterday}": 20,
      "#{one_hundred}": 100,
    }
    |> Enum.each(fn ({pnr, age}) ->
      {result, p} = Personnummer.new(Atom.to_string(pnr))

      assert result == :ok
      assert !is_nil(p)
      assert Personnummer.get_age(p) == age
    end)
  end

  test "test gender" do
    %{
      "19090903-6600": true,
      "19900101-0017": false,
      "800101-3294": false,
      "000903-6609": true,
      "800101+3294": false,
    }
    |> Enum.each(fn ({pnr, is_female}) ->

      {result, p} = Personnummer.new(Atom.to_string(pnr))

      assert result == :ok
      assert !is_nil(p)
      assert Personnummer.is_female?(p) == is_female
      assert Personnummer.is_male?(p) != is_female
    end)
  end

  test "test coordination number" do
    %{
      "800161-3294": true,
      "800101-3294": false,
      "640327-3813": false,
    }
    |> Enum.each(fn ({pnr, is_coordination}) ->

      {result, p} = Personnummer.new(Atom.to_string(pnr))

      assert result == :ok
      assert !is_nil(p)
      assert Personnummer.is_coordination_number(p) == is_coordination
    end)
  end
end
