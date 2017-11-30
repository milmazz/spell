defmodule SpellTest do
  use ExUnit.Case

  doctest Spell

  test "correction" do
    assert Spell.correction("speling") == "spelling"
    assert Spell.correction("korrectud") == "corrected"
    assert Spell.correction("bycycle") == "bicycle"
    assert Spell.correction("inconvient") == "inconvenient"
    assert Spell.correction("arrainged") == "arranged"
    assert Spell.correction("peotry") == "poetry"
    assert Spell.correction("peotryy") == "poetry"
    assert Spell.correction("word") == "word"
    assert Spell.correction("quintessential") == "quintessential"
  end

  test "probability" do
    assert Spell.probability("quintessential") == 0
    assert Spell.probability("the") > 0.07 and Spell.probability("the") < 0.08
  end

  test "dictionary" do
    dictionary = Spell.dictionary()
    assert Enum.count(dictionary) == 32198
    assert dictionary |> Map.values() |> Enum.sum() == 1_115_585
    assert Map.get(dictionary, "the") == 79809

    assert Spell.most_common(10) == [
             {"the", 79809},
             {"of", 40024},
             {"and", 38312},
             {"to", 28765},
             {"in", 22023},
             {"a", 21124},
             {"that", 12512},
             {"he", 12401},
             {"was", 11410},
             {"it", 10681}
           ]
  end
end
