defmodule Bpe do
  @moduledoc """
  Implimentation for the byte pair encoding algorithm.
  """

  @spec encode(String.t(), List) :: {String.t() , [Map]}
  @spec decode({String.t(),[Map]}) :: {String.t()}
  @spec walk(String.t(), acc :: Map) :: Map 
  @spec replace(String.t(),table :: Map,String.t()) :: String.t()
  @spec split_content(String.t(),integer()) :: Map
  
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
        new_content = async_replace(content,max_chunk,<<x>>,2)
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
    # we create the pool 
    pool = Repserver.init_pool(n)
    Enum.each(1..n,fn id -> 
      Repserver.assign_rep_job(pool,id,Map.get(parts,id),pattern,rep) 
    end)
    collected_result = Repserver.collect(n)
    Repserver.kill_pool(pool)
    collected_result
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
    part_len = total_len |> div(max)
    if part_len <= 1 do
      %{1 => content}
    else 
      Enum.reduce(1..max,%{},fn x,acc -> 
        if x == max do
          Map.put(acc,x,String.slice(content,(x-1)*part_len,total_len))
        else
          Map.put(acc,x,String.slice(content,(x-1)*part_len,x*part_len))
        end
      end)
    end 
  end 

  
end

encode_text = fn -> "input.txt"
  |> Bpe.read_lines(15_000) 
  |> Bpe.encode(?A..?Z) 
end 
encode_text |> Benchmark.time() |> IO.inspect()
