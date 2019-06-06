defmodule Spell do
  @moduledoc """
  Spell Corrector

  Inspired by Peter Norvig's essay: http://norvig.com/spell-correct.html

  """
  @file_path "lib/big.txt"
  @external_resource @file_path

  @pattern Regex.compile!("\\w+")
  @letters ?a..?z
  @words @file_path
         |> File.stream!()
         |> Stream.flat_map(fn line ->
           line = String.downcase(line)

           @pattern
           |> Regex.scan(line)
           |> List.flatten()
         end)
         |> Enum.reduce(%{}, fn word, acc ->
           Map.update(acc, word, 1, &(&1 + 1))
         end)

  @total_words @words |> Map.values() |> Enum.sum()

  @doc """
  Most probable spelling correction for word
  """
  def correction(word) do
    word
    |> String.downcase()
    |> candidates()
    |> Enum.max_by(&probability/1)
  end

  @doc """
  Probability of word
  """
  def probability(word, n \\ @total_words) do
    Map.get(@words, String.downcase(word), 0) / n
  end

  @doc """
  Current list of words
  """
  def dictionary, do: @words

  def most_common(amount) do
    @words
    |> Enum.sort(fn {_, x}, {_, y} -> x >= y end)
    |> Enum.take(amount)
  end

  # Generate possible spelling correction for word
  defp candidates(word) do
    cond do
      (candidates = known([word])) != [] ->
        candidates

      (candidates = word |> edits1() |> known()) != [] ->
        candidates

      (candidates = word |> edits2() |> known()) != [] ->
        candidates

      true ->
        [word]
    end
  end

  # The subset of words that appear in the dictionary of words
  def known(words) do
    @words
    |> Map.take(words)
    |> Map.keys()
  end

  # All edits that are one edit away from word
  def edits1(word) do
    splits = splits(word)

    splits
    |> deletes()
    |> transposes(splits)
    |> replaces(splits)
    |> inserts(splits)
    |> MapSet.to_list()
  end

  # All edits that are two edits away from word.
  def edits2(word) do
    for e1 <- edits1(word), e2 <- edits1(e1) do
      e2
    end
  end

  defp splits(word) do
    for idx <- 0..String.length(word) do
      {left, right} = String.split_at(word, idx)
      {String.to_charlist(left), String.to_charlist(right)}
    end
  end

  # Removes one letter
  defp deletes(splits) do
    for {left, [_ | right]} <- splits, right != [], into: MapSet.new() do
      :erlang.iolist_to_binary([left, right])
    end
  end

  # swap two adjacent letter
  defp transposes(set, splits) do
    for {left, [a, b | right]} <- splits, into: set do
      :erlang.iolist_to_binary([left, b, a, right])
    end
  end

  # change one letter for another
  defp replaces(set, splits) do
    for {left, [_ | right]} <- splits, c <- @letters, right != [], into: set do
      :erlang.iolist_to_binary([left, c, right])
    end
  end

  # add a letter
  defp inserts(set, splits) do
    for {left, right} <- splits, c <- @letters, into: set do
      :erlang.iolist_to_binary([left, c, right])
    end
  end
end
