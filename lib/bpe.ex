defmodule Bpe do
  @moduledoc """
  Implimentation for the byte pair encoding algorithm.
  """

  @spec encode(String.t(), List) :: {String.t() , [Map]}
  @spec decode({String.t(),[Map]}) :: {String.t()}
  @spec walk(String.t(), acc :: Map) :: Map 
  @spec replace(String.t(),table :: Map,String.t()) :: String.t()
  @spec split_content(String.t(),integer()) :: List
  
  def encode(str,rng) do
    init = str |> String.downcase()
    {final_content,tables} = 
      rng 
      |> Enum.reduce({init,[]},fn x , {content,table_acc} ->
        # we can also split the "walking" then "Map.merge"
        # the results (i think if we do this , its gonna mess up the algo)
        max_chunk = content 
          |> walk()
          |> Enum.max_by(&(elem(&1,1)))
          |> elem(0)
        # the replacing can be split to be handle by many threads
        # then concatenating the results in order
        new_content = async_replace(content,max_chunk,<<x>>,10)
        IO.puts("epoch done ...")
        {new_content,[{<<x>>,max_chunk} | table_acc]}
      end)
    {final_content,tables}
  end
 
  def decode({encoded,maps}) do
    maps
    |> Enum.reduce({encoded},fn x,acc -> 
      {replace(elem(acc,0),elem(x,0),elem(x,1))}
    end)
  end

  def walk(a,b \\ %{})
  def walk(<<_c::8>>,acc)  do
    acc
  end
  def walk(<<c::8,a::8, rest::binary>>,acc) do
    pair = <<c>> <> <<a>>
    new_map = acc |> Map.update(pair,1,&(&1+1))
    walk(<<a>> <> rest,new_map)
  end

  def replace(content,pattern,rep) do
    String.replace(content,pattern,rep) 
  end

  def async_replace(content,pattern,rep,n) do
    parts = split_content(content,n)

    tasks = parts
    |>  Enum.reduce([],fn x, acc ->
        [Task.async(fn -> String.replace(x,pattern,rep) end) | acc] 
        end)

    Enum.reduce(Enum.reverse(tasks), "", fn t, acc ->
      acc <> Task.await(t)
    end)

  end

  def read_lines(path,n) do
    path 
    |> File.stream!([], :line)
    |> Stream.map(&(String.trim(&1)))
    |> Enum.take(n)
    |> Enum.join(" ")
  end
  
  def split_content(content,max) do
    total_len = String.length(content)
    # IO.puts("Total length: #{total_len}")
    part_len = total_len |> div(max)

    if part_len <= 1 do
      [content]
    else
      Enum.reduce(0..max-1,[],fn x,acc ->
        if x*part_len+part_len+1 >= total_len do
          [String.slice(content, (x*part_len)..-1)|acc]  
        else
          [String.slice(content,x*part_len,part_len)|acc]  
        end
      end)
      |> Enum.reverse()
    end
  end 
end

encode_text = fn -> "input.txt"
  |> Bpe.read_lines(1_000)
  |> Bpe.encode(?A..?Z) 
  |> IO.inspect
end 
encode_text |> Benchmark.time() |> IO.inspect()

# "input.txt" 
# |> Bpe.read_lines(100) 
# |> Bpe.async_replace("h","H",10)
# |> IO.inspect()
# 
# IO.puts("DONE")
