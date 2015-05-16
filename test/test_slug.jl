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


importall Biryani.SlugifyConverters


# input_to_slug
@test Convertible("Hello world!") |> input_to_slug |> to_value == "hello-world"
@test Convertible("   Hello   world!   ") |> input_to_slug |> to_value == "hello-world"
@test Convertible("œil, forêt, ça, où...") |> input_to_slug |> to_value == "oeil-foret-ca-ou"
@test Convertible("   ") |> input_to_slug |> to_value === nothing
@test Convertible("") |> input_to_slug |> to_value === nothing
@test input_to_slug(Convertible("   Hello   world!   "), separator = ' ', transform = uppercase) |>
  to_value == "HELLO WORLD"
@test Convertible("   Hello   world!   ") |> input_to_slug(separator = ' ', transform = uppercase) |>
  to_value == "HELLO WORLD"
@test Convertible("   ") |> input_to_slug(separator = ' ', transform = uppercase) |> to_value === nothing
@test Convertible("") |> input_to_slug(separator = ' ', transform = uppercase) |> to_value === nothing
