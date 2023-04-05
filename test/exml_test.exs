defmodule ExmlTest do
  use ExUnit.Case
  doctest Exml

  test "Parse the sample" do
    xml =
      Path.join(__DIR__, "samples/dash_sample.xml")
      |> File.read!()
      |> Exml.parse!()

    res =
      xml
      |> Exml.first("MPD")
      |> Exml.first("Period")
      |> Exml.first("AdaptationSet")
      |> Exml.all("Representation")
      |> Enum.at(1)
      |> Exml.first("AudioChannelConfiguration")

    assert "urn:mpeg:dash:23003:3:audio_channel_configuration:2011" ==
             res.attrs["schemeIdUri"]
  end
end
