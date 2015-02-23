# Biryani -- A conversion and validation toolbox
# By: Emmanuel Raviart <emmanuel@raviart.com>
#
# Copyright (C) 2015 Emmanuel Raviart
# https://github.com/eraviart/Biryani.jl
#
# This file is part of Biryani.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


importall Biryani.JsonConverters


# input_to_json
@test Convertible("""{"a": 1, "b": [2, "three"]}""") |> input_to_json |> to_value == {"a" => 1, "b" => [2, "three"]}
@test Convertible("""      {"a": 1, "b": [2, "three"]}   """) |> input_to_json |> to_value ==
  {"a" => 1, "b" => [2, "three"]}
@test Convertible("null") |> input_to_json |> to_value == nothing
@test Convertible("   null   ") |> input_to_json |> to_value == nothing
@test Convertible("Hello world!") |> input_to_json |> to_value_error == ("Hello world!", "Invalid JSON")
@test Convertible("   Hello world!   ") |> input_to_json |> to_value_error == ("   Hello world!   ", "Invalid JSON")
@test Convertible("""{"a": 1, "b":""") |> input_to_json |> to_value_error == ("""{"a": 1, "b":""", "Invalid JSON")
@test Convertible("""    {"a": 1, "b":""") |> input_to_json |> to_value_error == ("""    {"a": 1, "b":""",
  "Invalid JSON")
@test Convertible("") |> input_to_json |> to_value == nothing
@test Convertible("   ") |> input_to_json |> to_value_error == ("   ", "Invalid JSON")
@test Convertible(nothing) |> input_to_json |> to_value === nothing
