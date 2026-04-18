defmodule Proyecto do
  def g1() do
    [
      [0,1],  [0,2],
      [1,2], [1,3],
      [2,3]
    ]
  end

  # lista a diccionario
  def list_dic(e) do
    Enum.reduce(e, %{}, fn [a , b] , acc ->
      Map.update(acc, a, [b], fn lista ->
      [b | lista]
    end)
    end)
  end

  def postset(edge, n) do
    edges
    |> Enum.filter(fn [src, _tnt] -> n == src end)

  end

  def powerset([]), do: [[]]

  def powerset([h|t]) do
    ps = powerset(t)
    ps ++ Enum.map(ps, fn ss -> [h| ss] end)
  end


  def transverse(edges, n , visited) do
    postset(edges,n)
    |> Enum.reduce([n], fn neighbor, acc->
      if neighbor not in visited do
        acc ++ transverse(edges, neighbor, [n| visited ])
    else
      acc
      end
    end)
  end

  def  proc(e) do
    ns = List.flatten(e)
    |> Enum.sort()
    |> Enum.dedup()


    """
    digraph G{
    #{Enum.map(ns, fn x -> "\tn#{x};" end) |> Enum.join("\n")}

    #{Enum.map(e, fn [a,b] -> "\tn#{a} -> n#{b}\n" end)}

    }
    """
  end


end
