defmodule BpeTest do
  use ExUnit.Case
  doctest Bpe

  test "wikipidea example" do
    assert "aaabdaaabac" |> Bpe.walk() |> IO.inspect() ==
             %{"aa" => 4, "ab" => 2, "ac" => 1, "ba" => 1, "bd" => 1, "da" => 1}
  end

  test "encoding" do
    assert "aaabdaaabac" |> Bpe.encode(?X..?Z) ==
             {"ZdZac", [{"Z", "Yb"}, {"Y", "Xa"}, {"X", "aa"}]}
  end

  test "decoding" do
    assert "aaabdaaabac" |> Bpe.encode(?X..?Z) |> Bpe.decode() |> elem(0) ==
             "aaabdaaabac"
  end
end
